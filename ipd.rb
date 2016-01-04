require 'csv'
require './pallet_flag_generator.rb'
require 'ruby-progressbar'

def ipd_month_code(workOrder)
  workOrder[0, 7]
end

def next_work_order_number(workOrder)
  workOrder[-3, 3] = next_work_order_seq(workOrder)
  workOrder
end

def next_work_order_seq(workOrder)
  start_number = workOrder[-3, 3].to_i
  format('%03d', (start_number + 1))
end

def col_blacklist?(head)
  s = 'dpc|crrt|listid|level|fico|pobox_flag|segment|income'
  s << '|ORDERRECORDID|cd|crid|dpbc|s.*x|add.*2'
  /#{s}/i =~ head ? true : false
end

def read_drop_sizes
  drops = []
  entry = -1
  puts 'Enter Drop Quantities (enter x or blank to stop)'
  while entry != 'x'
    print "Enter Drop #{drops.size + 1} size: "
    entry = gets.chomp
    entry = 'Y' unless entry
    drops << entry.to_i if entry != 'x' && entry != 'Y' && entry.to_i > 0
  end
  drops
end

def read_starting_wo_number
  print 'Enter first workorder in sequence: '
  gets.chomp
end

def read_dealer_pin
  print 'Enter dealer PIN: '
  gets.chomp
end

def read_dealer_purl
  print 'Enter mailing PURL: '
  gets.chomp
end

def read_job_po
  print 'Enter PO#: '
  gets.chomp
end

def nav_to_start_folder(workOrder)
  Dir.chdir '..'
  Dir.chdir ipd_month_code(workOrder)
  x = Dir.glob("#{workOrder}*").at(0)
  Dir.chdir x
  x
end

def find_input_csv
  arr = Dir.glob('*.csv')
  arr.delete_if { |e| /880\d\d\d\d-\d\d\d ?(for import)?/ =~ e }
  arr.at(0)
end

def header_to_ipd_header(source_file)
  current_headers = CSV.parse_line(File.open(source_file, &:gets))
  current_headers.delete_if { |h| col_blacklist?(h) }

  lname_i = current_headers.find_index { |l| /lname.*|last.*/i =~ l }
  mi_i = current_headers.find_index { |l| /mname.*|mi.*/i =~ l }
  current_headers[mi_i] = 'Salutation'
  current_headers[lname_i] = 'Full Name'
  current_headers << 'Pin'
  current_headers << 'PURL'
end

def write_header_to(header, write_file)
  CSV.open(write_file, 'a') { |out| out << header }
end

def ipd_seed(file, wo_number, pin_seq, dealer_pin, purl)
  jessica_first, jami_first = "Jessica #{wo_number}", 'Jami'
  jessica_address = '813 45th avenue north'
  jami_address = '3104 Cherry Palm Drive Ste 220'
  jessica_city, jami_city = 'St.Petersburg', 'Tampa'
  jessica_state = jami_state = 'FL'
  jessica_zip5, jami_zip5 = '33703', '33619'
  jessica_zip4, jami_zip4 = '3742', '8315'
  jessica_purl = "jessicacaruso#{purl}"
  jami_purl = "jamiblaisdell#{purl}"
  jessica_pin = "#{dealer_pin}-#{pin_seq}"
  jami_pin = "#{dealer_pin}-#{pin_seq + 1}"
  jessica_full, jami_full = "#{jessica_first} Caruso", 'Jami Blaisdell'

  h = CSV.parse_line(File.open(file, &:gets))

  address_i = h.find_index { |a| /add.*/i =~ a }
  city_i = h.find_index { |c| /.*city.*/i =~ c }
  state_i = h.find_index { |s| /.*state.*|st/i =~ s }
  zip5_i = h.find_index { |z5| /zip ?code|zip.*5?/i =~ z5 }
  zip4_i = h.find_index { |z4| /zip.*4/i =~ z4 }
  fname_i = h.find_index { |f| /fname.*|first.*/i=~ f }
  full_name_i = h.find_index { |fn| /Full Name/=~ fn }
  salutat_i = h.find_index { |sal| /Salutation/=~ sal }
  pin_i = h.find_index { |pi| /Pin/=~ pi }
  purl_i = h.find_index { |pu| /Purl/i=~ pu }
  je = Array.new(10)
  ja = Array.new(10)
  je[address_i] = jessica_address
  je[city_i] = jessica_city
  je[state_i] = jessica_state
  je[zip5_i] = jessica_zip5
  je[zip4_i] = jessica_zip4
  je[full_name_i] = jessica_full
  je[salutat_i] = jessica_full
  je[pin_i] = jessica_pin
  je[purl_i] = jessica_purl
  je[fname_i] = jessica_first
  ja[address_i] = jami_address
  ja[city_i] = jami_city
  ja[state_i] = jami_state
  ja[zip5_i] = jami_zip5
  ja[zip4_i] = jami_zip4
  ja[full_name_i] = jami_full
  ja[salutat_i] = jami_full
  ja[pin_i] = jami_pin
  ja[purl_i] = jami_purl
  ja[fname_i] = jami_first
  CSV.open(file, 'a+', headers: true) do |outfile|
    outfile << je
    outfile << ja
  end
end

def full_name(first, last, mi, suffix)
  name = ''
  if mi && mi != '' && mi != ' '
    name = "#{first} #{mi} #{last}"
  else
    name = "#{first} #{last}"
  end

  name << "-#{suffix}" if suffix && suffix != ''
  name
end

def salutat(first, last, suffix)
  name = "#{first} #{last}"
  name << "-#{suffix}" if suffix && suffix != ''
  name
end

def transform_row(row, pin, purl)
  tmphead = row.headers
  lname_i = tmphead.find_index { |l| /lname.*|last.*/i=~l }
  fname_i = tmphead.find_index { |l| /fname.*|first.*/i=~l }

  if row[fname_i]
    first = row[fname_i].capitalize.gsub(/\s+/, '') 
  else
    first = ""
  end
  if row[lname_i]
    last = row[lname_i].capitalize.gsub(/\s+/, '')
  else
    last = ""
  end
  sfx_i = tmphead.find_index { |l| /sfx.*|suffix.*|sufx.*/i =~ l }
  mi_i = tmphead.find_index { |l| /mi.*|mname/i =~ l }

  row[lname_i] = full_name(first, last, row[mi_i], row[sfx_i])

  row[mi_i] = salutat(first, last, row[sfx_i])
  row[fname_i] = first

  full_purl = "#{first.downcase}#{last.downcase}#{purl}"

  address2_i = tmphead.find_index { |l| /add.*2/i =~ l }

  if address2_i
    address = "#{row[(address2_i - 1)]} #{row[address2_i]}"
    row[address2_i - 1] = address
    row.delete(address2_i)
  end

  row << pin
  row << full_purl
  row.delete_if { |h| col_blacklist?(h[0]) }
  row
end

def create_output_csvs(source_file, start_WO, start_title, po_number)
  # Prep variables for use
  drop_sizes = read_drop_sizes
  dealer_pin = read_dealer_pin
  purl = read_dealer_purl
  purl = ".#{purl}" if purl[0] != '.'
  drop = 0
  current_title = start_title
  current_drop_number =  start_WO
  stop_at = drop_sizes[drop] - 1
  start_at = 0
  pin_seq = 100_099
  ipd_head = header_to_ipd_header(source_file)
  write_file = "#{current_drop_number} for import.csv"
  total_mailing = drop_sizes.reduce(:+)
  bar = ProgressBar.create(title: "Progress", total: total_mailing,
                           format: "%e %t: %%%p |%b%i|%c of %C ",
                           progress_mark: "=", remainder_mark: "-",
                           length: 120 )
  CSV.foreach(source_file, headers: true).each_with_index do |row, i|
    write_header_to(ipd_head, write_file) if i == start_at
    pin_seq += 1
    pin = "#{dealer_pin}-#{pin_seq}"

    CSV.open(write_file, 'a') { |out| out << transform_row(row, pin, purl) }
    bar.increment
    if i == stop_at
      ipd_seed(write_file, current_drop_number, pin_seq, dealer_pin, purl)
      drop += 1
      create_ipd_pallet_flag(current_drop_number, po_number, current_title)

      if drop < drop_sizes.size
        current_drop_number = next_work_order_number(current_drop_number)
        current_title = next_job_title(current_title)
        write_file = "#{current_drop_number} for import.csv"
        pin_seq = (100_100 * (drop + 1)) - 1
        pin = "#{dealer_pin}-#{pin_seq}"
        start_at += drop_sizes[drop]
        stop_at += drop_sizes[drop]
        nav_to_next_drop_folder("#{current_drop_number} #{current_title}")

      end
    end
    drop == drop_sizes.length ? break : true
  end
end

def nav_to_next_drop_folder(name)
  Dir.chdir '..'
  Dir.mkdir name
  Dir.chdir name
end

def ipd_style?(folderName)
  if folderName[3] == '-'
    return false
  else
    return true
  end
end

def job_title(folderName)
  if ipd_style?(folderName)
    return folderName[12, (folderName.length - 11)]
  else
    return folderName[11, (folderName.length - 10)]
  end
end

def next_job_title(jobTitle)
  /(?<mainTitle>.+)(?<current>\d+) of (?<total>\d+)\z/ =~ jobTitle
  mainTitle + (current.to_i + 1).to_s + ' of ' + total
end

start_wo = read_starting_wo_number
start_title = job_title(nav_to_start_folder(start_wo))
create_output_csvs(find_input_csv, start_wo, start_title, read_job_po)
