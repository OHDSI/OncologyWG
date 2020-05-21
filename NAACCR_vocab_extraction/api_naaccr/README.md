###API_NAACCR SCRAPER

##To run scraper on your machine and collect data, follow next steps:
(Linux OS)

1. Create a folder and setup virtual environment => open the terminal and in this directory and execute 'virtualenv -p python 3.6 env'
2. To activate virtual environment, run next command: "source env/bin/activate"
3. Run "pip install scrapy"
3. Run "scrapy startproject api_naaccr"
4. Install required packages "pip install -r requirements.txt"
5. Fill the file constants.py with your data to connect to the database
6. Run db.py . It will create all the tables required for this project (take a look at imports on the top of the code, they are different for python run and scrapy )
7. Go to settings.py and write 'DOWNLOAD_DELAY = 2'
8. Start scraping with command "scrapy crawl algorithm"