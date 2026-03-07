import os
import glob
import tabula
import pandas as pd
import re

def extract_tables():
    work_dir = "WORK"
    output_file = os.path.join(work_dir, "filtered_transactions.xlsx")
    
    pdf_files = glob.glob(os.path.join(work_dir, "*.pdf"))
    
    if not pdf_files:
        print("No PDF files found in the WORK directory.")
        return
    
    all_transactions = []
    
    # Regex to match: "MAR 28 MAR 31 SHOPPERS DRUG MART #34 CALGARY $20.32"
    # Also handles trailing text: "JUL 27 JUL 28 Upgrade Labs Canada Calgary $103.95 Credit Limit $5,000"
    # Also handles no-space dates: "JUN25 JUN26 SHOPEPRSDRUGMART#23CALGARY $3.14"
    pattern = re.compile(r'^([A-Z]{3}\s?\d{1,2})\s+([A-Z]{3}\s?\d{1,2})\s+(.+?)\s+(-?\$[,\d]+\.\d{2})(?:\s+.*)?$')
    
    for pdf_file in pdf_files:
        print(f"Processing {pdf_file} with Tabula...")
        try:
            import pdfplumber
            with pdfplumber.open(pdf_file) as pdf:
                for page in pdf.pages:
                    text = page.extract_text()
                    if text:
                        for line in text.split('\n'):
                            line = line.strip()
                            match = pattern.match(line)
                            if match:
                                trans_date, post_date, desc, amount = match.groups()
                                all_transactions.append({
                                    'Transaction Date': trans_date,
                                    'Posting Date': post_date,
                                    'Activity Description': desc.strip(),
                                    'Amount': amount,
                                    'Source_PDF': os.path.basename(pdf_file)
                                })
                                
        except Exception as e:
            print(f"Error processing {pdf_file}: {e}")
            
    if all_transactions:
        print(f"Extracted {len(all_transactions)} transactions. Combining and saving...")
        final_df = pd.DataFrame(all_transactions)
        final_df.to_excel(output_file, index=False)
        print(f"Successfully saved filtered tables to {output_file}")
    else:
        print("No matching transactions found in any of the processed PDFs using Tabula.")

if __name__ == "__main__":
    extract_tables()
