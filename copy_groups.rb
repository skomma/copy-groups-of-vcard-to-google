require 'optparse'
require 'pp'
require 'csv'

require 'bundler/setup'
require 'vcard'

params = ARGV.getopts('', 'vcard:', 'input:', 'output:')

# read groups from vCard file
puts "Reading groups from #{params['vcard']}..."
vcf = File.read(params['vcard'], encoding: 'SJIS:UTF-8')
# create fullname => group name hash
cards = Vcard.expand(Vcard.decode(vcf))
fn_groupname = Hash[
  cards.map do |card|
    key = card.find { |f| f.name == 'FN' }.value
    value = card.find { |f| f.name == 'X-GN' }.value
    [key, value]
  end
]
puts "Got #{fn_groupname.count} people."

# read Google Contacts CSV file
puts "Reading the original Google Contacts CSV..."
csv = CSV.read(params['input'], encoding: 'BOM|UTF-16LE:UTF-8', headers: true)
puts "Got #{csv.count} rows."

# add group got from vCard file
puts "Migrating group data to the Google Contacts CSV..."
csv.each do |row|
  row['Group Membership'] =
    row['Group Membership'].split(' ::: ')
      .push(fn_groupname[row['Name']]).join(' ::: ')
end

# write the generated csv data
puts "Writing migrated CSV..."
File.open(params['output'], 'wb+:UTF-16LE:UTF-8') do |f|
  f << csv.to_s
end
