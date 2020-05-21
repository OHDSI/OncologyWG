import json
import scrapy
import logging
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# for scrapy use this import:
from ..constants import DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME
from ..db import AlgorithmSchema, AlgorithmTable


Session = sessionmaker()

engine = create_engine('postgresql+psycopg2://{}:{}@{}:{}/{}'.format(DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME))
Session.configure(bind=engine)
session = Session()


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
handler = logging.FileHandler('debug_scraper.log')
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s : %(levelname)s : %(name)s : '
                                  '%(processName)s : %(funcName)s : %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)


class Algorithm(scrapy.Spider):

    name = 'algorithm'
    headers = {'X-SEERAPI-Key': '52d5c8826e0d07dc8782119ecf65e836',
               'accept': 'application/json',
               'X-CSRF-TOKEN': '4ccff9b1-0a5c-4931-bddc-abd739dab29a'}
    urls = ['https://api.seer.cancer.gov/rest/staging/eod_public/versions',
            'https://api.seer.cancer.gov/rest/staging/cs/versions',
            'https://api.seer.cancer.gov/rest/staging/tnm/versions',
            ]

    def start_requests(self):
        for url in self.urls:
            yield scrapy.Request(url=url, callback=self.parse_algorithm, headers=self.headers)

    def parse_algorithm(self, response):
        all_versions = json.loads(response.text)
        algorithm = response.url.split('/')[-2]
        for item in all_versions:
            url = f'https://api.seer.cancer.gov/rest/staging/{algorithm}/{item["version"]}/schemas'
            # print(item)
            yield scrapy.Request(url=url, callback=self.parse_version, headers=self.headers)

    def parse_version(self, response):
        version = response.url.split('/')[-2]
        algorithm = response.url.split('/')[-3]
        all_schemas = json.loads(response.text)
        for item in all_schemas:
            # print(item["id"])
            url = f'https://api.seer.cancer.gov/rest/staging/{algorithm}/{version}/schema/{item["id"]}'
            yield scrapy.Request(url=url, callback=self.parse_schema, headers=self.headers)

    def parse_schema(self, response):
        # print(response.text)
        all_data = json.loads(response.text)
        schema_id = all_data["id"]
        algorithm = all_data["algorithm"]
        version = all_data["version"]
        schema_description = all_data["title"]
        all_tables = all_data["inputs"]
        for table in all_tables:
            if "table" in table:
                naaccr_item = table["naaccr_item"]
                table_id = table["table"]
                table_name = table["name"]
                url = f'https://api.seer.cancer.gov/rest/staging/{algorithm}/{version}/table/{table_id}'
                yield scrapy.Request(url=url, callback=self.parse_table, headers=self.headers)
                db = AlgorithmSchema(algorithm=algorithm, version=version, schema_id=schema_id,
                schema_description=schema_description, naaccr_item=naaccr_item, table_id=table_id, table_name=table_name)
                session.merge(db)
        try:
            session.commit()
        except Exception as e:
            print(e)
            session.rollback()

    def parse_table(self, response):
        table_data = json.loads(response.text)
        algorithm = table_data["algorithm"]
        version = table_data["version"]
        table_id = table_data["id"]
        table_title = table_data["title"]
        table_name = table_data["name"]
        for row in table_data["rows"]:
            if row[0] != '':
                value_code = row[0]
                if len(row) > 1:
                    value_description = row[1].strip()
                else:
                    value_description = None
                db = AlgorithmTable(algorithm=algorithm, version=version, table_id=table_id, table_name=table_name,
                                table_title=table_title, value_code=value_code, value_description=value_description)
                session.merge(db)
        try:
            session.commit()
        except Exception as e:
            print(e)
            session.rollback()
