from sqlalchemy import Integer, Column, String, create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base

# to run db.py use this import
# from naaccr.naaccr.constants import DB_SCHEMA, DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME

# for scrapy use this import:
from .constants import DB_SCHEMA, DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME

metadata = MetaData(schema=DB_SCHEMA)
Base = declarative_base(metadata=metadata)


class LatestList(Base):

    __tablename__ = 'latest_list'

    id = Column(Integer, primary_key=True, autoincrement=True)
    item = Column(Integer)
    name = Column(String(100))


class Item(Base):

    __tablename__ = 'item'

    id = Column(Integer, primary_key=True, autoincrement=True)
    item = Column(Integer)
    name = Column(String(100))
    category = Column(String(100))
    code = Column(String(500))
    description = Column(String(500))


class SsdiData(Base):

    __tablename__ = 'ssdi'

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(500))
    site_inclusions = Column(String(500))
    hist_inclusions = Column(String(500))
    code = Column(Integer)
    description = Column(String(500))
    level = Column(Integer)
    parent_code = Column(Integer)


class EodSchema(Base):

    __tablename__ ='eod_schema'

    id = Column(Integer, primary_key=True, autoincrement=True)
    schema = Column(String(500))
    primary_site = Column(String(500))
    histology = Column(String(500))
    name_item = Column(String(500))
    naaccr_item = Column(String(500))


class EodItem(Base):

    __tablename__ ='eod_item'

    id = Column(Integer, primary_key=True, autoincrement=True)
    schema = Column(String(500))
    naaccr_item = Column(String(500))
    code = Column(String(500))
    description = Column(String(500))


class TnmSchema(Base):

    __tablename__ = 'tnm_schema'

    id = Column(Integer, primary_key=True, autoincrement=True)
    schema = Column(String(500))
    short_schema = Column(String(500))
    primary_site = Column(String(500))
    histology = Column(String(500))
    name_item = Column(String(500))
    naaccr_item = Column(String(500))
    main_data = Column(String(100))


class TnmItem(Base):

    __tablename__ = 'tnm_item'

    id = Column(Integer, primary_key=True, autoincrement=True)
    schema = Column(String(500))
    naaccr_item = Column(String(500))
    clinical_t = Column(String(500))
    clinical_t_display = Column(String(500))
    code = Column(String(500))
    description = Column(String(500))
    registrar_notes = Column(String(1000))


if __name__ == '__main__':
    engine = create_engine('postgresql+psycopg2://{}:{}@{}:{}/{}'.format(DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_NAME))
    Base.metadata.create_all(engine)
