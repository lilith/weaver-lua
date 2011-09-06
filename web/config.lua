
-- Puts all the definitions below in blog's namespace
module("weaver", package.seeall)

app_title = "Weaver Engine Prototype B 0.1"

cache_path = "page_cache"

copyright_notice = "Copyright 2011 Nathanael Jones"

about_blurb = [[This is an example of a blog built using Orbit. You
can browse posts and add comments, but to add new posts you have
to go directly to the database. This will be fixed in the future.]] 

blogroll = {
  { "http://slashdot.org", "Slashdot"},
  { "http://news.google.com", "Google News" },
  { "http://www.wikipedia.org", "Wikipedia" },
}

-- Uncomment this to send static files through X-Sendfile
-- use_xsendfile = true

database = {
--  driver = "mysql",
--  conn_data = { "blog", "root", "password" }
  driver = "sqlite3",
  conn_data = { weaver.real_path .. "/blog.db" }
}

recent_count = 7

strings = {}

strings.en = {
  home_page_name = "Home Page",
  about_title = "About this Blog",
  last_posts = "Recent Posts",
  blogroll_title = "Links",
  archive_title = "Archives",
  anonymous_author = "Anonymous",
  no_posts = "No published posts.",
  published_at = "Published at",
  comments = "Comments",
  written_by = "Written by",
  on_date = "at",
  new_comment = "New comment",
  no_comment = "You forgot the comment!",
  form_name = "Name:",
  form_email = "Email:",
  form_url = "Site:",
  italics = "italics",
  bold = "bold",
  link = "link",
  send = "Send"
}

language = "en"

strings = strings[language]

months = {}

months.en = { "January", "February", "March", "April",
    "May", "June", "July", "August", "September", "October",
    "November", "December" }

weekdays = {}


weekdays.en = { "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday" }

-- Utility functions

time = {}
date = {}
month = {}

local datetime_mt = { __call = function (tab, date) return tab[language](date) end }

setmetatable(time, datetime_mt)
setmetatable(date, datetime_mt)
setmetatable(month, datetime_mt)

local function ordinalize(number)
  if number == 1 then
    return "1st"
  elseif number == 2 then
    return "2nd"
  elseif number == 3 then
    return "3rd"
  else
    return tostring(number) .. "th"
  end
end

function time.en(date)
  local time = os.date("%H:%M", date)
  date = os.date("*t", date)
  return months.en[date.month] .. " " .. ordinalize(date.day) .. " " ..
     date.year .. " at " .. time
end

function date.en(date)
  date = os.date("*t", date)
  return weekdays.en[date.wday] .. ", " .. months.en[date.month] .. " " ..
     ordinalize(date.day) .. " " .. date.year 
end

function month.en(month)
  return months.en[month.month] .. " " .. month.year
end

