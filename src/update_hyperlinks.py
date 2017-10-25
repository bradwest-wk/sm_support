# python3
# Script accesses a google sheets document and a drive folder with html files.
# for each element name and cik in the sheet, it finds the associated url
# for the correct html file and creates a hyperlink in the correct cell

from __future__ import print_function
import httplib2
import os
import webbrowser

from apiclient import discovery
from oauth2client.client import flow_from_clientsecrets
from oauth2client import tools

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

SCOPES = 'https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive'
CLIENT_SECRET_FILE = 'client_secret.json'
APPLICATION_NAME = 'Create Hyperlinks'

# The "flow" is specific to the OAuth2 client and detailed on the Google
# APIs website
src_dir = os.path.dirname(os.path.abspath(__file__))
# print(src_dir)
flow = flow_from_clientsecrets(os.path.join(src_dir, 'client_secret.json'),
                               scope=SCOPES,
                               redirect_uri='urn:ietf:wg:oauth:2.0:oob')
auth_uri = flow.step1_get_authorize_url()
webbrowser.open_new(auth_uri)

auth_code = ""

# Asks user to give the authentication code which opens in browser
while len(auth_code) == 0:
    auth_code = input("Enter authorization code: ")

credentials = flow.step2_exchange(auth_code)

http_auth = credentials.authorize(httplib2.Http())
drive_service = discovery.build('drive', 'v3', http=http_auth)
sheets_service = discovery.build('sheets', 'v4', http=http_auth)

# ID for folder with html files
level_one_id = '0Bz6cFFRZYZPtVGxrZW9Fd3h1cm8'

# ID for google sheets in which hyperlinks will be placed
sheets_id = "***"

# The preface for the hyperlink
hlink_form = "https://drive.google.com/open?id="


def getFiles(service, folder_id):
    """Get a list of files in a drive folder

    Args:
        service: Drive API service instance.
        folder_id: Folder of interest ID

    Returns:
        A python list of dictionaries with id and file name
    """

    query = "'" + folder_id + "' in parents"
    items = []
    page_token = None
    while True:
        results = service.files().list(q=query,
                                       pageSize=1000,
                                       fields="nextPageToken, files(id, name)",
                                       pageToken=page_token).execute()
        items.extend(results.get('files', []))
        page_token = results.get('nextPageToken', None)
        if page_token is None:
            break
    return items


def createHyper(files, preface):
    """Create a hyperlink of the given drive file id

    Args:
        files: a list of dictionaries of files. Needs to have 'id' and
        'name' keywords
        preface: the hyperlink preface to use, a string

    Returns:
        a dictionary of files, updated with hyperlinks, cik, and element name
        with key as the name
    """
    for file in files:
        file['hyperlink'] = preface+file['id']
        file['cik'] = file['name'].split('-')[0]
        file['elname'] = file['name'].split('-')[1].split('.')[0]

    file_dict = {item['name']: item for item in items}
    return file_dict


def getCikElement(service, sheet_id, cik_range, el_range):
    """Access ciks and element names from sheets (via grabbing a range)

    :param service: Sheets API service instance
    :param sheet_id: ID of sheet to query
    :param cik_range: Range of ciks in A1 notation
    :param el_range: Range of elements in A1 notation
    :return: cik and element valueRange object
    """
    cik = service.spreadsheets().values().get(
        spreadsheetId=sheet_id, range=cik_range).execute()
    elements = service.spreadsheets().values().get(
        spreadsheetId=sheet_id, range=el_range).execute()
    return cik, elements

def getHyperlinks(service, sheet_id, hyperlink_range):
    """Access current hyperlinks in the sheet

    :param service: Sheets API service instance
    :param sheet_id: ID of sheet to query
    :param hyperlink_range: Range of ciks in A1 notation
    :return: hyperlinks values list
    """
    hyperlinks = service.spreadsheets().values().get(
        spreadsheetId=sheet_id, range=hyperlink_range).execute()
    return hyperlinks['values']


def hyperList(hyperlinks, ciks, elements, file_dict, letter_set):
    """Creates a parallel array of hyperlinks

    :param ciks: the cik valueRange object that contains the ciks
    :param elements: Element name valueRange object
    :param file_dict: Dictionary of hyperlinks, ciks, element names
    :return: a list of hyperlinks parallel to the cik and element value lists
    """
    # hyperlinks = []
    # for (cik, element) in zip(ciks['values'], elements['values']):
    #     name = cik[0].zfill(10)+"-"+element[0]+".html"
    #     try:
    #         hyperlinks.append(
    #             "=HYPERLINK(\""+file_dict[name]['hyperlink']+"\")")
    #     except:
    #         hyperlinks.append("")
    # return hyperlinks

    cik = ciks['values']
    element = elements['values']
    hyper = [''] * len(cik)
    for i in range(len(cik)):
        if element[i][0][0] in letter_set:
            name = cik[i][0].zfill(10) + "-" + element[i][0] + ".html"
            try:
                hyper[i] = \
                    "=HYPERLINK(\"" + file_dict[name]['hyperlink'] + "\")"
            except:
                pass
        else:
            try:
                hyper[i] = hyperlinks[i][0]
            except:
                pass
    return hyper


if __name__ == '__main__':
    print("** Creating files dictionary **")
    items = getFiles(drive_service, level_one_id)
    print("** Building hyperlinks **")
    files = createHyper(items, hlink_form)
    print("** Getting current Hyperlinks **")
    hyper = getHyperlinks(sheets_service, sheets_id, "Level 1 Detail!G2:G")
    print("** Creating parallel array of hyperlinks **")
    ciks, elements = getCikElement(
        sheets_service, sheets_id, "Level 1 Detail!D2:D", "Level 1 Detail!A2:A")
    desired_update = {'S','T','U','V'}
    hyperlinks = hyperList(hyper, ciks, elements, files, desired_update)
    # print(hyperlinks[(len(hyperlinks)-20):])
    data = [
        {
            'range': "Level 1 Detail!G2:G",
            'majorDimension': "COLUMNS",
            'values': [hyperlinks]
        },
        # Additional ranges to update ...
    ]
    body = {
      'valueInputOption': "USER_ENTERED",
      'data': data
    }

    print("** Writing data to sheet **")
    result = sheets_service.spreadsheets().values().batchUpdate(
        spreadsheetId=sheets_id, body=body).execute()
    print("** DONE **")

# if __name__ == '__main__':
#     hyper = getHyperlinks(sheets_service, sheets_id, "Level 1 Detail!G2:G")
#     print(len(hyper))
#     print(hyper[:50])
