# Program to take in the Job name, PO number, and title of an IPD job and 
# generate the bottom half of the pallet flag for printing
# Load in gem dependency
require 'prawn'
# Load the arial font family into the program
def set_arial_family
  # Stores location of font files for use
  font_families.update('Arial' => {  normal: './arial.ttf',
                                     italic: './ariali.ttf',
                                     bold: './arialbd.ttf',
                                     bold_italic: './arialbi.ttf' })
  # Set current working font to Arial
  font('Arial')
end
# Set initial font family and move cursor to start
def start_ipd_flag
  # Load in font family and set font
  # set_arial_family
  # Set initial font size
  font_size 28
  # Set starting cursor position
  move_down 425
end
# Stores and returns string containing the drop ship fine-print
def npl_fineprint
  # Change font size to be smaller
  font_size 12
  # Set string values in readable line form
  npl1 = 'DROP SHIP PROVIDER: Drop Ship Direct, Tampa, FL.'
  npl2 = 'Please call 813-806-5465 if any problems at time of delivery'
  # Return concatenated strings
  npl1 + ' ' + npl2
end
# Contains IPD specific strings used for creating the pallet flag
def draw_ipd_flag(job_number, po_number, job_name)
  # Draws the mail date line where the cursor was initially set to
  text 'Mail Date:                                                 __/__/____'
  # Move the cursor down to location of the Job and PO info line
  move_down 34
  # Sets main_line by interpolating job and PO info with static string
  main_line = 'Job No: ' + job_number + " / <b>IPD PO: #{po_number}</b>"
  # Draws the main_line with inline formatting to produce bold section
  text main_line, inline_format: true
  # Move cursor again to please the Name line
  move_down 5
  # Draw the name line
  text 'IPD Name: ' + job_name
  # Draw the fineprint line at origin. Letting it flow puts it on next page
  draw_text npl_fineprint, at: [0, 0]
end
# Contains pdf generation block
def create_ipd_pallet_flag(job_number, po_number, job_name)
  # Create base document, set layout and margin, initiate block
  Prawn::Document.generate("#{job_number} flag.pdf",
                           page_layout: :landscape,
                           margin: 23) do
    # Load in font and set initial size and cursor placement
    start_ipd_flag
    # Uses supplied parameters to draw flag
    # TO DO: Make this an anonymous function call for similar PDFs.
    # (Pass in a draw function and a parameters function)
    draw_ipd_flag(job_number, po_number, job_name)
  end
end
