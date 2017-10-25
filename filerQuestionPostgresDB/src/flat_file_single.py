'''
Functions for:
1. Accessing Google Sheets via the python api
2. Cleaning records without element names, questions, or disclosures
3. Writing data to newline delimited json records
'''

import sys
import httplib2
import os
import numpy as np
import pandas as pd

from apiclient import discovery
from oauth2client import client
from oauth2client import tools
from oauth2client.file import Storage

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

# =============================================================================
# Credential Parameters
# =============================================================================
# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/sheets.googleapis.com-python-quickstart.json
SCOPES = 'https://www.googleapis.com/auth/spreadsheets ' \
         'https://www.googleapis.com/auth/drive'
CLIENT_SECRET_FILE = 'client_secret.json'
APPLICATION_NAME = 'West Local Access'


def get_creds():
    """Gets user credentials from storage or runs the OAuth2 flow if credentials
    have nor been stored or are invalid

    :return:
        Credentials, the obtained credential
    """
    src_dir = os.path.dirname(os.path.abspath(__file__))
    cred_dir = os.path.join(src_dir, '.credentials')
    if not os.path.exists(cred_dir):
        os.makedirs(cred_dir)
    cred_path = os.path.join(cred_dir, 'disclosure_requirements.json')

    store = Storage(cred_path)
    credentials = store.locked_get()
    if not credentials or credentials.invalid:
        flow = client.flow_from_clientsecrets(
            os.path.join(src_dir, 'client_secret.json'),
            scope=SCOPES,
            redirect_uri='urn:ietf:wg:oauth:2.0:oob')
        flow.user_agent = APPLICATION_NAME
        if flags:
            credentials = tools.run_flow(flow, store, flags)
    return credentials


def authorize_access():
    credentials = get_creds()
    http = credentials.authorize(httplib2.Http())
    return http


def get_files_recursive(service, folder_id):
    """Get a list of spreadsheet files in a folder with a

    Args:
        service: Drive API service instance.
        folder_id: the drive folder id to query within

    Returns:
        A list of ids and names of
    """
    query = "'" + folder_id + "' in parents and name contains 'ASC'"
    fldr_mime = 'application/vnd.google-apps.folder'
    shts_mime = 'application/vnd.google-apps.spreadsheet'
    items = []
    page_token = None
    while True:
        results = service.files().list(q=query,
                                       pageSize=1000,
                                       spaces='drive',
                                       fields="nextPageToken, "
                                              "files(id, name, mimeType)",
                                       pageToken=page_token).execute()
        files = results.get('files', [])
        page_token = results.get('nextPageToken', None)
        for f in files:
            if f['mimeType'] == shts_mime:
                items.append(f)
            elif f['mimeType'] == fldr_mime:
                items.extend(get_files_recursive(service, f['id']))
        if page_token is None:
            break
    return items


def records_df(service, identifier, wrksht):
    """
    Gets all records from a single google sheets spreadsheet and the correct
    worksheet, returning a pandas dataframe

    :param service: sheets service to use
    :param identifier: The id of the spreadsheet, the key of the spreadsheet
    :param wrksht: Name of the worksheet
    :return: valueRange object
    """
    range_names = [
        wrksht+"!A1:D",
        wrksht+"!K1:K",
        wrksht+"!M1:M",
        wrksht+"!P1:X"
    ]
    values = service.spreadsheets().values().batchGet(
        spreadsheetId=identifier, ranges=range_names,
        majorDimension='COLUMNS').execute()
    return values


def to_df(inp):
    """
    Converts a value range object to a pandas dataframe

    :param inp: the valueRange object
    :return: pandas dataframe
    """
    colnames = ['topic', 'asc_paragraph_ref1', 'sx_paragraph_ref',
                'asc_paragraph_ref2', 'ref_id', 'question',
                'presentation_parent', 'calculation_parent', 'element_name',
                'element_label', 'balance_type', 'period_type', 'data_type',
                'namespace', 'definition']
    tmp_dct = {}
    ranges = inp['valueRanges']
    i = 0
    for rnge in ranges:
        try:
            columns = rnge['values']
        except:
            columns = []
        for column in columns:
            column = [np.nan if v is '' else v for v in column]
            tmp_dct[colnames[i]] = pd.Series(column[1:])
            i += 1
    df = pd.DataFrame(tmp_dct)
    return df


def filter_missing(df):
    """
    Filters rows with missing element_names or questions

    :param df Dataframe to filter on, with necessary columns
    :return A Dataframe, filtered
    """
    df = df[pd.notnull(df['element_name'])]
    df = df[pd.notnull(df['question'])]
    return df


def combine_df(service, items, wrksht, taxonomy):
    """
    Takes an input of Google spreadsheet ids and outputs a combined pandas
    dataframe.

    :param service: The spreadsheet service to use
    :param items: A list of dictionaries with the name and id of the sheet
    :param wrksht The name of the worksheet to query needs to be identical
    :param taxonomy The taxonomy used for the disclosures
    across the sheets
    :return: The combined pandas dataframe
    """
    dframes = []
    # ids = [x['id'] for x in items]
    for item in items:
        tmp_df = to_df(records_df(service, item['id'], wrksht))
        tmp_df['disclosure'] = item['name']  # add disclosure
        tmp_df['taxonomy'] = taxonomy
        tmp_df['unit'] = np.nan
        tmp_df = filter_missing(tmp_df)
        dframes.append(tmp_df)
    full = pd.concat(dframes, ignore_index=True)
    # arrange in the correct format
    full = full[['disclosure', 'taxonomy', 'topic', 'asc_paragraph_ref1',
                    'sx_paragraph_ref', 'asc_paragraph_ref2', 'ref_id',
                    'question', 'presentation_parent', 'calculation_parent',
                    'element_name', 'element_label', 'balance_type',
                    'period_type', 'data_type', 'namespace', 'definition',
                    'unit']]
    return full


def to_json(df, pth):
    """
    Converts a pandas df to newline delimited json

    :param df: The pandas df
    :param pth: The path to write to
    :return: writes to json, newline delimited
    """
    f = open(pth, 'w')
    for row in df.iterrows():
        row[1].dropna().str.strip().to_json(f)
        f.write('\n')
    f.close()


def main(pth, sheets=None):
    """
    Accesses google sheets, finds relevant sheets if necessary, gets data,
    cleans data, combines multiple sheets and exports to json.

    :param sheets: The google sheets to use, or leave none to get all
    :param pth: the path to write json to
    :return:
    """
    http_auth = authorize_access()
    drive_service = discovery.build('drive', 'v3', http=http_auth)
    sheets_service = discovery.build('sheets', 'v4', http=http_auth)
    if sheets is None:
        sheets = get_files_recursive(drive_service, TOPICAL_REVIEW)
    full = combine_df(sheets_service, sheets,
                      'Disclosure Requirements', '2017_review')
    to_json(full, pth)


# =============================================================================
# Parameters to pass to main()
# =============================================================================
TOPICAL_REVIEW = '***'
sheets = [{'id': '***',
           'name': '***'}]
path = '/tmp/tst.json'

# =============================================================================
# Run 'er
# =============================================================================

if __name__ == '__main__':
    main(path, sheets=sheets)
