#!/usr/bin/env ruby
require 'resolv'
require 'net/smtp'
require 'csv'

def get_emails(row)
  fn = "#{row[0]}".strip.downcase
  mn = "#{row[1]}".strip.downcase
  ln = "#{row[2]}".strip.downcase
  emails = [fn, ln, fn+ln, fn+'.'+ln, fn[0].to_s+ln, fn[0].to_s+'.'+ln, fn+ln[0].to_s, fn+'.'+ln[0].to_s, fn[0].to_s+ln[0].to_s, fn[0].to_s+'.'+ln[0].to_s,
            ln+fn, ln+'.'+fn, ln+fn[0].to_s, ln+'.'+fn[0].to_s, ln[0].to_s+fn,ln[0].to_s+'.'+fn, ln[0].to_s+fn[0].to_s, ln[0].to_s+'.'+fn[0].to_s,
            fn[0].to_s+mn[0].to_s+ln, fn[0].to_s+mn[0].to_s+'.'+ln, fn+mn[0].to_s+ln, fn+'.'+mn[0].to_s+'.'+ln, fn+mn+ln, fn+'.'+mn+'.'+ln,
            fn+'-'+ln,fn[0].to_s+'-'+ln, fn+'-'+ln[0].to_s, fn[0].to_s+'-'+ln[0].to_s, ln+'-'+fn, ln+'-'+fn[0].to_s, ln[0].to_s+'-'+fn, ln[0].to_s+'-'+fn[0].to_s, fn[0].to_s+mn[0].to_s+'-'+ln, fn+'-'+mn[0].to_s+'-'+ln, fn+'-'+mn+'-'+ln,
            fn+'_'+ln,fn[0].to_s+'_'+ln, fn+'_'+ln[0].to_s, fn[0].to_s+'_'+ln[0].to_s, ln+'_'+fn, ln+'_'+fn[0].to_s, ln[0].to_s+'_'+fn, ln[0].to_s+'_'+fn[0].to_s, fn[0].to_s+mn[0].to_s+'_'+ln, fn+'_'+mn[0].to_s+'_'+ln, fn+'_'+mn+'_'+ln]
  emails.map { |e| e.gsub('--','-').gsub('__','_').gsub('..','.') }.uniq
end

results = CSV.open("results.csv", "w")
results << ['First Name', 'Middle Name', 'Last Name', 'Domain', 'Email']
CSV.foreach("contacts.csv", :encoding => 'ISO-8859-1:UTF-8') do |row|
  not_found = true
  puts row.inspect
  addresses = get_emails(row)
  domain = row[3].gsub('http://', '').gsub('www.','').split('/')[0]
  puts "Resolving MX records for #{domain}..."
  mx_records = Resolv::DNS.open.getresources domain, Resolv::DNS::Resource::IN::MX
  addresses.each do |address|
    success = false
    begin
      mx_server  = mx_records.first.exchange.to_s
    rescue Exception => e
      puts "ERROR IN MX RECORDS==>>"+e.inspect
      results << [row[0],row[1],row[2], domain, nil]
      success = true
      break
    end
    puts "Connecting to #{mx_server}..."

      begin
        Net::SMTP.start mx_server, 25 do |smtp|
          smtp.helo "loldomain.com"
          smtp.mailfrom "test@loldomain.com"

          puts "Pinging #{address}..."

          puts "-" * 50

          begin
            smtp.rcptto address+'@'+domain
            results << [row[0],row[1],row[2], domain, address+'@'+domain]
            puts "success"
            success = true
            not_found = false
          rescue Net::SMTPFatalError => err
            puts "PING ERROR====>>>"+err.inspect
            puts "Address probably doesn't exist."
          end
        end
      rescue Exception => e
        puts "ERROR===>>"+e.inspect
        break
      end
    if success
      break
    end
  end
  if not_found
    results << [row[0],row[1],row[2], domain, nil]
  end
end
