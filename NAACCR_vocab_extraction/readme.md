###ANAACCR SCRAPERS

##To run scrapers on your machine and collect data, follow next steps:
(Linux OS)


1. Import project from the repository and setup virtual environment within it=> open the terminal in this directory and execute 'virtualenv -p python 3.6 env'
2. To activate virtual environment, run next command: "source env/bin/activate"
3. Run "pip install scrapy"

Then, depending on what scraper ypu want to deploy, follow next instructions

Naaccr_API
4. Uncomment default = api_naaccr.settings and project = api_naaccr in the scrapy.cfg file
5. Open 'api_naaccr' 
5. Install required packages "pip install -r requirements.txt"
6. Fill the file constants.py with your data to connect to the database
7. Run db.py . It will create all the tables required for this project (take a look at imports on the top of the code, they are different for python run and scrapy )
8. Go to settings.py and write 'DOWNLOAD_DELAY = 2'
9. Start scraping with command "scrapy crawl algorithm"

Naaccr
4. Uncomment default = naaccr.settings and project = naaccr in the scrapy.cfg file
5. Open 'naaccr' 
6. Install required packages "pip install -r requirements.txt"
7. Fill the file constants.py with your data to connect to the database
8. Run db.py . It will create all the tables required for this project (take a look at imports on the top of the code, they are different for run and scrapy )
9. Execute next commands in the terminal: 
    -scrapy crawl latest 
(parsing data from https://api.seer.cancer.gov/rest/naaccr/latest   using API)
    -scrapy crawl ssdi 
(parsing data from https://api.seer.cancer.gov/rest/surgery/latest/tables   using API)
    -scrapy crawl eod 
(parsing data from https://staging.seer.cancer.gov/eod_public/list/1.4/  without API)
    -scrapy crawl tnm
(parsing data from https://staging.seer.cancer.gov/tnm/list/1.9/   without API)

Pay attention to the imports and the comments on the top of the parse_api.py and db.py file.