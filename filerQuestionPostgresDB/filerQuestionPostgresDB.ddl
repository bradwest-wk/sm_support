-- TODO: Not sure where to place the calculation, presentation, etc. references. They don't really do anything unless
-- we need to access parent-child relationships, in which case we'll need to process the calculation/presentation reference
-- files to extract the From --> To relationships.

SET statement_timeout=0; -- turns off functionality to abort a statement that takes more than a specified number of milliseconds

SET client_encoding = 'UTF8'; -- sets client-side encoding
SET standard_conforming_strings = off; -- treat backslashes as escape characters
SET check_function_bodies = false; -- disables validation of the function body string during create function
SET client_min_messages = warning; -- sets which message levels are set to the client
SET escape_string_warning = off; -- don't warn about backslashes in ordinary strings

SET search_path = public, pg_catalog;

-- unconditionally try to drop each table before creating it according to common practice
DROP TABLE IF EXISTS question CASCADE;
DROP TABLE IF EXISTS reference CASCADE;
DROP TABLE IF EXISTS element CASCADE;
DROP TABLE IF EXISTS disclosure CASCADE;
DROP TABLE IF EXISTS axis CASCADE;
DROP TABLE IF EXISTS member CASCADE;

-- unconditionally try to drop each sequence before creating it according to common practice
DROP SEQUENCE IF EXISTS seq_question;
DROP SEQUENCE IF EXISTS seq_reference;
DROP SEQUENCE IF EXISTS seq_element;
DROP SEQUENCE IF EXISTS seq_axis;
DROP SEQUENCE IF EXISTS seq_member;
-- Do we also want a seq_disclosure?

CREATE SEQUENCE seq_element;
ALTER TABLE public.seq_element OWNER TO postgres;

CREATE TABLE element (
    element_id bigint NOT NULL DEFAULT nextval('seq_element'),
    element_name character varying(1024), -- Should we change this to line_item_name?
    label character varying(1024), -- In current xbrl there is no limit on number of labels. A new feature is only one label?
    period_type character varying(16),
    unit text,
    balance_type character varying(16),
    data_type character varying(1024),
    namespace character varying(1024),
    definition text,
    PRIMARY KEY (element_id)
);
CREATE INDEX element_index02 ON element USING btree (element_name);

ALTER TABLE public.element OWNER TO postgres;


CREATE SEQUENCE seq_question;
ALTER TABLE public.seq_question OWNER TO postgres;

CREATE TABLE question (
    question_id bigint NOT NULL DEFAULT nextval('seq_question'),
    element_id bigint REFERENCES element (element_id), -- Note, we will not be able to add questions that do not reference an exisitng element in the elements table
    question text,
    disclosure text,
    taxonomy text,
    PRIMARY KEY (question_id)
);
CREATE INDEX question_index02 ON question USING btree (element_id);

ALTER TABLE public.question OWNER TO postgres;


CREATE SEQUENCE seq_reference;
ALTER TABLE public.seq_reference OWNER TO postgres;

CREATE TABLE reference (
    -- Not sure how this table is supposed to look since I believe it's references to paragraphs and whatnot
    reference_id bigint NOT NULL DEFAULT nextval('seq_reference'),
    element_id bigint REFERENCES element (element_id),
    reference text,
    PRIMARY KEY (reference_id)
);
CREATE INDEX reference_index02 ON reference USING btree (element_id);

ALTER TABLE public.reference OWNER TO postgres;




CREATE TABLE disclosure (
    element_id bigint REFERENCES element (element_id),
    disclosure text,
    PRIMARY KEY (element_id, disclosure) -- OK?
);

ALTER TABLE public.disclosure OWNER TO postgres;


CREATE SEQUENCE seq_axis;
ALTER TABLE public.seq_axis OWNER TO postgres;

CREATE TABLE axis (
    axis_id bigint NOT NULL DEFAULT nextval('seq_axis'),
    axis_name character varying(1024),
    axis_namespace character varying(1024),
    element_id bigint REFERENCES element (element_id),
    defined_members text[], -- I think we can either have this be member_id or the member_name. Name keeps us from having to join to member to get the names
    PRIMARY KEY (axis_id)
);
CREATE INDEX axis_index02 ON axis USING btree (element_id);

ALTER TABLE public.axis OWNER TO postgres;


CREATE SEQUENCE seq_member;
ALTER TABLE public.seq_member OWNER TO postgres;

CREATE TABLE member (
    member_id bigint NOT NULL DEFAULT nextval('seq_member'),
    member_name character varying(1024),
    member_namespace character varying(1024),
    element_id bigint REFERENCES element (element_id),
    axis_id bigint REFERENCES axis (axis_id),
    PRIMARY KEY (member_id)
);
CREATE INDEX member_index02 ON member USING btree (element_id);
CREATE INDEX member_index03 ON member USING btree (axis_id);






