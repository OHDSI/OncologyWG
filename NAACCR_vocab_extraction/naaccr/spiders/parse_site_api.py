import json
import scrapy
from lxml import html
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import urllib.parse
# # for scrapy use this import:
from ..constants import DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME
from ..db import LatestList, Item, SsdiData, EodSchema, EodItem, TnmItem, TnmSchema

# for Run use this import:
# from naaccr.naaccr.constants import DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME
# from naaccr.naaccr.db import LatestList, Item, Ssdi


Session = sessionmaker()

engine = create_engine('postgresql+psycopg2://{}:{}@{}:{}/{}'.format(DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME))
Session.configure(bind=engine)
session = Session()


class Latest(scrapy.Spider):

    name = 'latest'
    headers = {'X-SEERAPI-Key': '52d5c8826e0d07dc8782119ecf65e836'}
    url = 'https://api.seer.cancer.gov/rest/naaccr/latest'

    def start_requests(self):
        request = scrapy.Request(url=self.url, callback=self.parse, headers=self.headers)
        yield request

# parsing the first page -- latest
#     def parse(self, response):
#         json_data = json.loads(response.text)
#         for data in json_data:
#             db = LatestList(item=data["item"], name=data["name"])
#             session.merge(db)
#             yield scrapy.Request(response.urljoin(f'/rest/naaccr/latest/item/{data["item"]}'),
#                                  callback=self.parse_item_data, headers=self.headers)
#         try:
#             session.commit()
#         except Exception as e:
#             print(e)
#             session.rollback()

# parsing detail page for each item -- latest/item/
    def parse_item_data(self, response):
        json_data = json.loads(response.text)
        html_doc = html.fromstring(json_data["documentation"])
        current_item = {}
        current_item['item'] = json_data['item']
        current_item['name'] = json_data['name']
        if html_doc.xpath('//strong[contains(text(), "Description")]'):
            description = html_doc.xpath('//strong[contains(text(),"Description")]/parent::*/parent::*'
                                         '/following-sibling::*')[0].text_content()
            if 'Site-specific codes' in description:
                current_item['category'] = 'SSDI'
            else:
                current_item['category'] = None
        if html_doc.xpath('//*[@class="content chap10-para"]/table/tr'):
            for tr in html_doc.xpath('//*[@class="content chap10-para"]/table/tr'):
                if len(tr.xpath('td[contains(@class, "code-nbr")]/text()')):
                    code = tr.xpath('td[contains(@class, "code-nbr")]/text()')[0]
                    if code == '*':
                        current_item['code'] = None
                    else:
                        current_item['code'] = code
                    if len(tr.xpath('td[contains(@class, "code-desc")]/text()')):
                        current_item['description'] = tr.xpath('td[contains(@class, "code-desc")]/text()')[0]
                    else:
                        current_item['description'] = None
                    db = Item(**current_item)
                    session.merge(db)
                    try:
                        session.commit()
                    except Exception as e:
                        print(e)
                        session.rollback()
        else:
            db = Item(**current_item)
            session.merge(db)
        try:
            session.commit()
        except Exception as e:
            print(e)
            session.rollback()


class Ssdi(scrapy.Spider):

    name = 'ssdi'
    headers = {'X-SEERAPI-Key': '52d5c8826e0d07dc8782119ecf65e836'}
    url = 'https://api.seer.cancer.gov/rest/surgery/latest/tables'

    def start_requests(self):
        request = scrapy.Request(url=self.url, callback=self.parse, headers=self.headers)
        yield request

# get all table names
    def parse(self, response):
        json_data = json.loads(response.text)
        for data in json_data:
            encoded_data = urllib.parse.quote(data)
            yield scrapy.Request(response.urljoin('/rest/surgery/latest/table?title={}'.format(encoded_data)),
                                 callback=self.parse_table_data, headers=self.headers)
# parse each element of table
    def parse_table_data(self, response):
        json_data = json.loads(response.text)
        data = json_data["row"]
        current_item = {}
        current_item["title"] = json_data["title"]
        current_item["site_inclusions"] = json_data.get("site_inclusions")
        current_item["hist_inclusions"] = json_data.get("hist_exclusions")
        parent = {}
        for item in data:
            if item.get("code"):
                current_item["code"] = int(item["code"])
                current_item["description"] = item["description"]
                current_item["level"] = int(item["level"])
                if current_item["level"] == 0:
                    parent[0] = current_item["code"]
                    current_item["parent_code"] = None
                elif current_item["level"] == 1:
                    parent[1] = current_item["code"]
                    current_item["parent_code"] = parent[0]
                elif current_item["level"] == 2:
                    parent[2] = current_item["code"]
                    current_item["parent_code"] = parent[1]
                elif current_item["level"] == 3:
                    parent[3] = current_item["code"]
                    current_item["parent_code"] = parent[2]
                else:
                    raise NotImplementedError()

                db = SsdiData(**current_item)
                session.merge(db)
            else:
                continue
        try:
            session.commit()
        except Exception as e:
            print(e)
            session.rollback()


class Eod(scrapy.Spider):

    name = 'eod'
    # headers = {'X-SEERAPI-Key': '52d5c8826e0d07dc8782119ecf65e836'}
    url = 'https://staging.seer.cancer.gov/eod_public/list/1.4/'

    def start_requests(self):
        request = scrapy.Request(url=self.url, callback=self.parse)
        yield request

# get all urls of schemas
    def parse(self, response):
        schema_urls = response.xpath('//*[@id="content"]/div/div/div/div/a/@href').extract()
        for schema in schema_urls:
            yield scrapy.Request(response.urljoin(f'{schema}'), callback=self.parse_schema_table)

# parse data from the table of items of the schema
    def parse_schema_table(self, response):
        current_schema = {}
        current_schema["schema"] = response.xpath('//*[@id="content"]/div/div/h2/text()').extract_first()
        top_table = response.xpath('//*[@id="content"]/div/div/div[1]/table/tbody/tr')
        for tr in top_table:
            current_schema["primary_site"] = tr.xpath('td[1]/text()').extract_first()
            current_schema["histology"] = tr.xpath('td[2]/text()').extract_first().strip()
            for row in response.xpath('//*[@id="section1"]/div/table/tbody/tr'):
                if 'SSDI' in row.xpath('td[6]/text()').extract():
                    current_schema["name_item"] = row.xpath('td[1]/a/text()').extract_first()
                    current_schema["naaccr_item"] = row.xpath('td[4]/a/text()').extract_first()
                    next_url = row.xpath('td[1]/a/@href').extract_first()
                    db = EodSchema(**current_schema)
                    session.merge(db)
                    yield scrapy.Request(response.urljoin(next_url), callback=self.parse_item_table)

            try:
                session.commit()
            except Exception as e:
                print(e)
                session.rollback()

# parse codes of each item
    def parse_item_table(self, response):
        # naaccr_item = response.xpath('//*[@id="content"]/div/div/div[3]/a/text()').extract_first()
        all_rows = response.xpath('//*[@id="section2"]/div/table/tbody/tr')
        for row in all_rows:
            if len(row.xpath('td[1]/text()').extract()):
                schema = response.xpath('/html/body/div[3]/div/a[3]/text()').extract_first()
                code = row.xpath('td[1]/text()').extract_first()
                description = row.xpath('td[2]/text()').extract_first()
                if len(response.xpath('//*[@id="content"]/div/div/div[3]/a/text()').extract()):
                    naaccr_item = response.xpath('//*[@id="content"]/div/div/div[3]/a/text()').extract_first()
                else:
                    naaccr_item = response.xpath('//*[@id="content"]/div/div/div[2]/a/text()').extract_first()
                db = EodItem(naaccr_item=naaccr_item, code=code, description=description, schema=schema)
                session.merge(db)
        try:
            session.commit()
        except Exception as e:
            print(e)
            session.rollback()


class Tnm(scrapy.Spider):

    name = 'tnm'
    url = 'https://staging.seer.cancer.gov/tnm/list/1.9/'

    def start_requests(self):
        request = scrapy.Request(url=self.url, callback=self.parse)
        yield request

# get all schema names and urls
    def parse(self, response):
        schema_urls = response.xpath('//*[@id="content"]/div/div/div/div/a/@href').extract()
        for schema in schema_urls:
            yield scrapy.Request(response.urljoin(f'{schema}'), callback=self.parse_main_table)

# get all data from main data item
    def parse_main_table(self, response):
        current_item = {}
        current_item["schema"] = response.xpath('//*[@id="content"]/div/div/h2/text()').extract_first()
        current_item["short_schema"] = response.xpath('/html/body/div[3]/div/text()').extract()[2].strip()
        for tr in response.xpath('//*[@id="content"]/div/div/div[1]/table/tbody/tr'):
            current_item["primary_site"] = tr.xpath('td[1]/text()').extract_first()
            current_item["histology"] = tr.xpath('td[2]/text()').extract_first()
            if 'Main' not in response.xpath('//*[@id="section1"]/h3[1]/text()').extract_first():
                current_item["main_data"] = 'No main data'
                db = TnmSchema(**current_item)
                session.merge(db)
            else:
                for tr in response.xpath('//*[@id="section1"]/div[1]/table/tbody/tr'):
                    current_item["name_item"] = tr.xpath('td[1]/a/text()').extract_first()
                    next_url = tr.xpath('td[1]/a/@href').extract_first()
                    current_item["naaccr_item"] = tr.xpath('td[4]/a/text()').extract_first()
                    db = TnmSchema(**current_item)
                    session.merge(db)
                    yield scrapy.Request(response.urljoin(f'{next_url}'), callback=self.parse_item_table)
        try:
            session.commit()
        except Exception as e:
            print(e)
            session.rollback()

# get all data about items
    def parse_item_table(self, response):

        for tr in response.xpath('//*[@id="section2"]/div/table/tbody/tr'):
            if len(tr.xpath('td[1]/text()').extract()):
                schema = response.xpath('/html/body/div[3]/div/a[3]/text()').extract_first()
                naaccr_item =response.xpath('//h3[contains(text(), "NAACCR Item")]/following-sibling::*/text()').extract_first()
                if response.xpath('//*[@id="section2"]/div/table/thead/tr/th[1][contains(text(), "Code")]'):
                    code = tr.xpath('td[1]/text()').extract_first()
                    description = tr.xpath('td[2]/text()').extract_first()
                    db = TnmItem(naaccr_item=naaccr_item, description=description, schema=schema, code=code)
                    session.merge(db)
                else:
                    clinical_t = tr.xpath('td[1]/text()').extract_first()
                    clinical_t_display = tr.xpath('td[2]/text()').extract_first()
                    description = tr.xpath('td[3]/text()').extract_first()
                    registrar_notes = tr.xpath('td[4]/text()').extract_first()
                    db = TnmItem(naaccr_item=naaccr_item, clinical_t=clinical_t, clinical_t_display=clinical_t_display,
                                 description=description, registrar_notes=registrar_notes, schema=schema)
                    session.merge(db)
        try:
            session.commit()
        except Exception as e:
            print(e)
            session.rollback()
