require 'optparse'
require 'pp'
require 'csv'

require 'bundler/setup'
require 'vcard'

opts = OptionParser.new
params = {}
opts.on(
  '--vcard VCARD',
  "(Required) Input vCard file (.vcf). The group infos in this file will be used."
) { |v| params[:vcard] = v }
opts.on(
  '--input CSV',
  "(Required) Input Google Contacts CSV file (.csv)"
) { |v| params[:input] = v }
opts.on(
  '--output CSV',
  "(Required) Output Google Contacts CSV file (.csv). The migrated result will be written to this file."
) { |v| params[:output] = v }
opts.on_tail("-h", "--help", "Show this message") do
  puts opts
  exit
end
opts.parse!(ARGV)

need_opts = [:vcard, :input, :output].select { |opt| params[opt].nil? }
if need_opts.size > 0
  display_opts = need_opts.map { |opt| "--#{opt}" }.join ','
  $stderr.puts "You must specify #{display_opts}"
  exit 255
end

# read groups from vCard file
puts "Reading groups from #{params[:vcard]}..."
vcf = File.read(params[:vcard], encoding: 'SJIS:UTF-8')
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
csv = CSV.read(params[:input], encoding: 'BOM|UTF-16LE:UTF-8', headers: true)
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
File.open(params[:output], 'wb+:UTF-16LE:UTF-8') do |f|
  f << csv.to_s
end
