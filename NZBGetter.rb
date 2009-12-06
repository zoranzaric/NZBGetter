#!/usr/bin/env ruby
# NZBGetter takes a list of search-terms from the command line.
# It then downloads every NZB found for this search-term.
#
# There are two options:
# * -f -- the file in which the ids for the downloaded nzbs are stored, so no nzb is downloaded twice
# * -d -- the directory in which the downloaded nzbs are stored
#
# Author::	Zoran Zaric (mailto:zz@zoranzaric.de)
# v0.1 - 06.12.2009

require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'cgi'

class NZBGetter
  def initialize
    @downloaded_file = ".downloaded"
    @download_dir    = ""
    @search_terms = Array.new
    skip_next = false
    ARGV.each_with_index do |arg, index|
      if skip_next
        skip_next = false
	next
      end
      if arg == "-d"
        @download_dir = ARGV[index + 1]
	unless @download_dir == ""
	  unless /\/$/.matches @download_dir
	    @download_dir = @download_dir + '/'
	  end
	end
	skip_next = true
      elsif arg == "-f"
        @downloaded_file = ARGV[index + 1]
	skip_next = true
      else
        @search_terms.push(arg)
      end
    end
  end

  # parses the file with the already downloaded ids
  def parse_downloaded
    if File.exists?(@downloaded_file)
      File.foreach(@downloaded_file) do |line|
        @downloaded.push(line.to_i)
      end
    end
  end

  # generates the rss-url for the given search-term
  def get_rss_url(search_term)
    "http://www.nzbclub.com/nzbfeed.aspx?ss=" + CGI::escape(search_term)
  end

  # returns the id for the given item as an integer
  def get_id(item)
    /(\d+)$/.match(item.link)[1].to_i
  end
  
  # generates the nzb-url for the given item
  def get_nzb_url(item)
    "http://www.nzbclub.com/nzbdownload.aspx?cid=" + get_id(item).to_s
  end

  # generates the local filename for the item
  def get_nzb_filename(item)
    item.title.gsub!(/\W/, '_')
    item.title.gsub!(/^_*/, '')
    item.title.gsub!(/_*$/, '') + ".nzb"
  end

  # downloads the nzb for a given item
  def download_nzb(item)
    unless @downloaded.include?(get_id(item))
      filename = get_nzb_filename(item)
      url = get_nzb_url(item)
      writeOut = open(@download_dir + filename, "wb")
      writeOut.write(open(url).read)
      writeOut.close
      downloaded_file = File.new(@downloaded_file, "a+")
      downloaded_file.puts(get_id(item))
      downloaded_file.close
      @downloaded.push(get_id(item))
    else
      puts "didn't download"
    end
  end

  # downloads all nzbs for a given search-term
  def download_nzbs(search_term)
    source = get_rss_url(search_term)
    content = ""
    open(source) do |s| content = s.read end
    rss = RSS::Parser.parse(content, false)
    rss.items.each do |item|
      puts "downloading " + item.title + "..."
      download_nzb(item)
    end
  end

  # downloads all nzbs for all search-terms
  def download
    @downloaded = Array.new
    parse_downloaded
    @search_terms.each do |search_term|
      download_nzbs(search_term)
    end
  end
end

getter = NZBGetter.new
getter.download
