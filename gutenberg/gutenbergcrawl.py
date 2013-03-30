#!/usr/bin/python
# version 0.1 Wenming Ye   2/25/2012
#Extract English and Text only content out of the Gutenberg DVD. 2010
# If you have questions, please contact me for the latest version.
# feel free to modify the scripts to your needs.
# STEP 1: Run this in the Cygwin Environment.  if you don't want to use Cygwin, you can modify "cp command embeded in the script".
# This file parses the html index pages (TITLES) and find english Language books and their ZIP resource URLs.
# Run this in the gutenberg main INDEXES dir in gutenberg  "www.gutenberg.org/INDEXES"
# Removes pdf, html, and images, and non-english items.   All the zip files will be copied into the INDEXES/zips
# STEP 2: Then you can extract all the zip files by running >>>>find ./ -name "*.zip" -exec unzip -o {} \;<<<<
# STEP 3: find ./ -name "*.txt" // that's your list of text.   You should see about 26942 total # of text files.
# STEP 4:  remove *readme.txt   you can use the find utility again. find ./ -name "*readme.txt" -exec rm {} \;
# STEP 5:  YOU CAN DO THAT FOR htm, html, etc.   
# You will end up with 26900 relatively clean set of files.  find ./ -name "*.txt" -exec cp {} my_text_dir \; 
# TODO:   get rid of UTF8 duplicates vs. ASCII.

from HTMLParser import HTMLParser
from htmlentitydefs import name2codepoint
import urllib
import os
import commands

# Class for parsing Book HTML page to extract the ZIP (actual URL for the books).
class BookPropertyHTMLParser(HTMLParser):
	def __init__(self):
		HTMLParser.__init__(self)
		self.url_list = []
		
	def handle_starttag(self, tag, attrs):
		if (tag == "a"):
			for attr in attrs:
				attr_string = "".join(attr)
				attr_string = attr_string[4:]
				
				if ((attr_string.count(".zip") != 0) or (attr_string.count(".txt") != 0)):
					if (attr_string.count("h.zip") != 0):#  remove anything that ends with h.zip( verfified)
						continue
						# pass, do nothing
					elif (attr_string.count("_images.zip") != 0):
						continue
						# pass, do nothing 
					elif (attr_string.count("_pdf.zip") != 0):
						# pass, do nothing
						continue
					else:
						self.url_list.append(attr_string)
						commands.getstatusoutput('cp ' + attr_string + " zips") # change to xcopy for windows cmd.

# parsing the title page to find any English language book (English)					
class TitleFilesHTMLParser(HTMLParser):
	def __init__(self):
		HTMLParser.__init__(self)
		self.book_title = ""
		self.book_attr = ""
		self.book_property_list = []
		
	def handle_starttag(self, tag, attrs):
		if (tag == "h3"):
			self.book_title = ""
			self.book_attr = ""
		if (tag == "a"):
			for attr in attrs:
				self.book_attr += "".join(attr)
				self.book_attr = self.book_attr[4:]
				
	def handle_endtag(self, tag):
		if (tag == "h3"):
			if (self.book_title.count("(English)") !=0):
				self.book_property_list.append(self.book_attr.upper())
			
	def handle_data(self, data):
		self.book_title += data

# get the zip URLs on the Book HTML property page.	
def get_zip_urls(book_url):		
	book_url_string = "file://"+os.getcwd()+"/" + book_url
	book_page_file = urllib.urlopen(book_url_string)
	book_page_file_string = book_page_file.read()
	book_page_file.close()
	book_page_parser = BookPropertyHTMLParser()
	book_page_parser.feed(book_page_file_string)
	print book_url, book_page_parser.url_list  # you might want to get rid of duplicates for each book.  Some of them have utf8, and ASCII.


# Loop through the title page and find all the Book Property URLs.
def get_english_only_urls(title_page_url):
	file = urllib.urlopen(title_page_url)
	file_string = file.read()
	file.close()
	parser = TitleFilesHTMLParser()
	parser.feed(file_string)
	global total_books 
	total_books += len(parser.book_property_list)
	#parser.book_property_list = []
	#parser.book_property_list.append('../etext/28964.html')
	
	#  go parse each file and get the zip file URL
	for book_url in parser.book_property_list:
		get_zip_urls(book_url)
		
	
#  MAIN FUNCTION HERE  run this in the gutenberg main INDEXES dir in gutenberg  "www.gutenberg.org/INDEXES"

# get a list of the title pages a-z, other	
if not os.path.exists("zips"):
    os.makedirs("zips")

titleFileList = []	    
total_books = 0
for i in range(ord('A'), ord('Z')+1):
	titleFileList.append(chr(i))	
titleFileList.append('OTHER')

# now for the title page list, find the URL for the Book's HTML description page.  
# On the description page extract the ZIP file URL for the actual book
for i in titleFileList:
	title_page_url = "file://"+os.getcwd()+"/TITLES_" + i + ".HTML"
	get_english_only_urls(title_page_url)
	
print total_books
#

