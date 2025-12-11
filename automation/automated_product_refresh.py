#!/usr/bin/env python
# coding: utf-8

# In[6]:


import requests
import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime
import time
import logging
import sys

# CONFIGURATION
SQL_SERVER = 'THOTH\\SQLEXPRESS'
DATABASE = 'EcommerceDB'
TABLE_NAME = 'api_products_live'
LOG_FILE = 'pipeline_log.txt'

# Search terms for product variety
SEARCH_TERMS = [
    'chocolate', 'yogurt', 'bread', 'cheese', 'milk',
    'coffee', 'tea', 'juice', 'cereal', 'pasta',
    'rice', 'cookies', 'chips', 'water', 'soda'
]

# SETUP LOGGING
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)

# FUNCTION 1: PULL FROM API
def pull_products_from_api():

    logging.info("="*60)
    logging.info("STARTING API DATA PULL")
    logging.info("="*60)
    
    all_products = []
    
    for term in SEARCH_TERMS:
        logging.info(f"Searching for: {term}")
        
        url = "https://world.openfoodfacts.org/cgi/search.pl"
        params = {
            "search_terms": term,
            "page": "1",
            "page_size": "50",
            "json": "1"
        }

            
        try:
            response = requests.get(url, params=params, timeout=60)
            
            if response.status_code == 200:
                data = response.json()
                products = data.get('products', [])
                all_products.extend(products)
                logging.info(f"Retrieved {len(products)} products")
            else:
                logging.warning(f"API returned status {response.status_code}")
                
        except Exception as e:
            logging.error(f"Error fetching {term}: {e}")
        
        time.sleep(1) 
    
    logging.info(f"\n TOTAL PRODUCTS COLLECTED: {len(all_products)}")
    return all_products

# FUNCTION 2: PROCESS DATA
def process_products(products):
    
    logging.info("\nPROCESSING PRODUCT DATA")
    
    # Convert to DataFrame
    df = pd.DataFrame(products)
    
    # Select and rename columns
    columns_map = {
        'product_name': 'product_name',
        'brands': 'brand',
        'categories': 'category',
        'nutrition_grade_fr': 'nutrition_grade',
        'code': 'product_id'
    }
    
    # Keep only columns we have
    available_cols = {k: v for k, v in columns_map.items() if k in df.columns}
    df_clean = df[list(available_cols.keys())].copy()
    df_clean = df_clean.rename(columns=available_cols)
    
    # Handle missing values
    df_clean['product_name'] = df_clean['product_name'].fillna('Unknown Product')
    df_clean['brand'] = df_clean['brand'].fillna('Unknown Brand')
    df_clean['category'] = df_clean['category'].fillna('Uncategorized')
    
    # Add timestamp
    df_clean['last_updated'] = datetime.now()
    
    logging.info(f"Processed {len(df_clean)} products")
    logging.info(f"Columns: {df_clean.columns.tolist()}")
    
    return df_clean

# FUNCTION 3: LOAD TO SQL
def load_to_sql(df):
    
    logging.info("\nLOADING DATA TO SQL SERVER")
    
    try:
        # Create connection
        connection_string = f'mssql+pyodbc://{SQL_SERVER}/{DATABASE}?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'
        engine = create_engine(connection_string)
        
        # Load data (replace existing table)
        df.to_sql(TABLE_NAME, engine, if_exists='replace', index=False)
        
        logging.info(f"Successfully loaded {len(df)} products to {TABLE_NAME}")

        return True, len(df)

    except Exception as e:
        logging.error(f"SQL Load Failed: {e}")
        return False, 0

# FUNCTION 4: GENERATE SUMMARY
def generate_summary(products_count, success):
    
    logging.info("\n" + "="*60)
    logging.info("PIPELINE EXECUTION SUMMARY")
    logging.info("="*60)
    logging.info(f"Execution Time: {datetime.now()}")
    logging.info(f"Status: {'SUCCESS' if success else 'FAILED'}")
    logging.info(f"Products Processed: {products_count}")
    logging.info(f"Database Table: {TABLE_NAME}")
    logging.info("="*60)

# MAIN EXECUTION
def main():
    start_time = datetime.now()
    
    try:
        # Step 1: Pull from API
        products = pull_products_from_api()
        
        if not products:
            logging.error("No products retrieved from API")
            return False
        
        # Step 2: Process data
        df_clean = process_products(products)
        
        # Step 3: Load to SQL
        success, count = load_to_sql(df_clean)
        
        # Step 4: Summary
        generate_summary(count, success)
        
        execution_time = (datetime.now() - start_time).total_seconds()
        logging.info(f"\nTotal execution time: {execution_time:.2f} seconds")
        
        return success
        
    except Exception as e:
        logging.error(f"\nPIPELINE FAILED: {e}")
        generate_summary(0, False)
        return False

# RUN THE PIPELINE
if __name__ == "__main__":
    logging.info("\nAUTOMATED PRODUCT REFRESH PIPELINE STARTED")
    success = main()
    sys.exit(0 if success else 1)


# In[ ]:




