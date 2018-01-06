require 'optparse'
require 'pp'

require 'bundler/setup'
require 'vcard'

params = ARGV.getopts('', 'vcard:', 'input:', 'output:')

# read groups from vCard file
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
pp fn_groupname
