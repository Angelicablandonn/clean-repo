/* ==========================================================================
   FINANCIAL DATA INGESTION & CANONICAL MODELING  -  SNOWFLAKE (SQL ONLY)
   Author : Dangelly Angelica Blandon Negrete
   --------------------------------------------------------------------------
   Self-contained & runnable: paste into a Snowflake worksheet and "Run All".
   No stages or file uploads required - real sample data is embedded as
   literals via PARSE_XML / PARSE_JSON, then processed by the SAME logic that
   a production stage-based load would use.

   ARCHITECTURE (medallion)
     RAW    : land documents verbatim (VARIANT) + CSV catalogs (all-string)
     STAGE  : flatten -> cast (TRY_TO_*) -> validate -> dedupe -> NORMALIZE
     CANON  : conformed star  (DIM_CUSTOMER, DIM_PRODUCT, FCT_TRANSACTION_LINE)
              + VW_TRANSACTION_SUMMARY (per-transaction) + VW_DATA_QUALITY_METRICS
     QUARANTINE : rejected rows kept with error_reason + raw_record (audit)
   ========================================================================== */

-- ===== 0. ENVIRONMENT =====================================================
CREATE DATABASE IF NOT EXISTS FIN_INGEST;
CREATE SCHEMA   IF NOT EXISTS FIN_INGEST.RAW;
CREATE SCHEMA   IF NOT EXISTS FIN_INGEST.STAGE;
CREATE SCHEMA   IF NOT EXISTS FIN_INGEST.CANON;
CREATE SCHEMA   IF NOT EXISTS FIN_INGEST.QUARANTINE;
USE SCHEMA FIN_INGEST.RAW;

-- ===== 1. RAW : land documents & catalogs ================================
CREATE OR REPLACE TABLE RAW.CLIENTA_XML  (src_file STRING, loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(), doc VARIANT);
CREATE OR REPLACE TABLE RAW.CLIENTC_JSON (src_file STRING, loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(), doc VARIANT);

INSERT INTO RAW.CLIENTA_XML  (src_file, doc) SELECT 'ClientA_Transactions_1.xml', PARSE_XML($$<SalesData client="ClientA" generatedAt="2025-11-12T10:45:00Z">

    <!-- TXN-1001: valid with extra field + negative quantity -->
    <Transaction>
        <TransactionID>TXN-1001</TransactionID>
        <Order>
            <OrderID>ORD-5001</OrderID>
            <OrderDate>2025-11-10</OrderDate>
            <Customer>
                <CustomerID>CUST-A-0001</CustomerID>
                <Name>
                    <FirstName>John</FirstName>
                    <LastName>Doe</LastName>
                </Name>
                <Email>john.doe@example.com</Email>
                <LoyaltyTier>GOLD</LoyaltyTier>
            </Customer>
        </Order>
        <Items>
            <Item>
                <SKU>SKU-A-001</SKU>
                <Description>Wireless Mouse</Description>
                <Quantity>2</Quantity>
                <UnitPrice currency="USD">25.99</UnitPrice>
            </Item>
            <Item>
                <SKU>SKU-A-002</SKU>
                <Description>Keyboard</Description>
                <Quantity>-1</Quantity>
                <UnitPrice currency="USD">45.50</UnitPrice>
            </Item>
        </Items>
        <Payment>
            <Method>CreditCard</Method>
            <Amount currency="USD">97.48</Amount>
        </Payment>
    </Transaction>

    <!-- TXN-1001 duplicate -->
    <Transaction>
        <TransactionID>TXN-1001</TransactionID>
        <Order>
            <OrderID>ORD-5001</OrderID>
            <OrderDate>2025-11-10</OrderDate>
            <Customer>
                <CustomerID>CUST-A-0001</CustomerID>
                <Name>
                    <FirstName>John</FirstName>
                    <LastLastName>Doe</LastLastName>
                </Name>
                <Email>john.doe@example.com</Email>
            </Customer>
        </Order>
        <Items>
            <Item>
                <SKU>SKU-A-001</SKU>
                <Description>Wireless Mouse</Description>
                <Quantity>2</Quantity>
                <UnitPrice currency="USD">25.99</UnitPrice>
            </Item>
        </Items>
        <Payment>
            <Method>CreditCard</Method>
            <Amount currency="USD">97.48</Amount>
        </Payment>
    </Transaction>

    <!-- TXN-1002: invalid fields -->
    <Transaction>
        <TransactionID></TransactionID>
        <Order>
            <OrderID>ORD-5002</OrderID>
            <OrderDate></OrderDate>
            <Customer>
                <CustomerID>CUST-A-0002</CustomerID>
                <Name>
                    <FirstName></FirstName>
                    <LastName>Unknown</LastName>
                </Name>
                <Email></Email>
            </Customer>
        </Order>
        <Items>
            <Item>
                <SKU></SKU>
                <Description>Faulty Item</Description>
                <Quantity>1</Quantity>
                <UnitPrice currency="USD">0</UnitPrice>
            </Item>
        </Items>
        <Payment>
            <Method>CreditCard</Method>
            <Amount currency="USD">0</Amount>
        </Payment>
    </Transaction>

    <!-- TXN-1003: extra nested field, positive/negative mix -->
    <Transaction>
        <TransactionID>TXN-1003</TransactionID>
        <Order>
            <OrderID>ORD-5003</OrderID>
            <OrderDate>2025-11-11</OrderDate>
            <Customer>
                <CustomerID>CUST-A-0003</CustomerID>
                <Name>
                    <FirstName>Jane</FirstName>
                    <LastName>Smith</LastName>
                </Name>
                <Email>jane.smith@example.com</Email>
                <Metadata>
                    <SignupSource>MobileApp</SignupSource>
                    <MarketingOptIn>true</MarketingOptIn>
                </Metadata>
            </Customer>
        </Order>
        <Items>
            <Item>
                <SKU>SKU-A-003</SKU>
                <Description>USB-C Charger</Description>
                <Quantity>3</Quantity>
                <UnitPrice currency="USD">19.99</UnitPrice>
            </Item>
            <Item>
                <SKU>SKU-A-004</SKU>
                <Description>Screen Protector</Description>
                <Quantity>-2</Quantity>
                <UnitPrice currency="USD">9.99</UnitPrice>
            </Item>
        </Items>
        <Payment>
            <Method>PayPal</Method>
            <Amount currency="USD">59.97</Amount>
            <Fees>
                <ProcessingFee>1.50</ProcessingFee>
            </Fees>
        </Payment>
    </Transaction>

    <!-- TXN-1004: missing email, extra unexpected field -->
    <Transaction>
        <TransactionID>TXN-1004</TransactionID>
        <Order>
            <OrderID>ORD-5004</OrderID>
            <OrderDate>2025-11-11</OrderDate>
            <Customer>
                <CustomerID>CUST-A-0004</CustomerID>
                <Name>
                    <FirstName>Robert</FirstName>
                    <LastName>King</LastName>
                </Name>
                <Email></Email>
                <Tags>
                    <Tag>new_customer</Tag>
                    <Tag>promo_user</Tag>
                </Tags>
            </Customer>
        </Order>
        <Items>
            <Item>
                <SKU>SKU-A-005</SKU>
                <Description>Gaming Headset</Description>
                <Quantity>1</Quantity>
                <UnitPrice currency="USD">79.99</UnitPrice>
            </Item>
        </Items>
        <Payment>
            <Method>CreditCard</Method>
            <Amount currency="USD">79.99</Amount>
        </Payment>
    </Transaction>

</SalesData>$$);
INSERT INTO RAW.CLIENTC_JSON (src_file, doc) SELECT 'transactions.json',          PARSE_JSON($${
  "client": "ClientC",
  "batchTimestamp": "2025-11-20T12:00:00Z",
  "transactions": [
    {
      "id": "C-TXN-3001",
      "order": {
        "id": "C-ORD-9001",
        "date": "2025-11-08",
        "customer": {
          "id": "C-CUST-5001",
          "name": "Chris Evans",
          "email": "cevans@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-001",
          "description": "Smartwatch",
          "qty": 1,
          "price": {
            "amount": 149.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "CreditCard",
        "total": 149.99
      }
    },
    {
      "id": "C-TXN-3001",
      "order": {
        "id": "C-ORD-9001",
        "date": "2025-11-08",
        "customer": {
          "id": "C-CUST-5001",
          "name": "Chris Evans",
          "email": "cevans@example.com"
        }
      },
      "items": [],
      "payment": {
        "method": "CreditCard",
        "total": 149.99
      }
    },
    {
      "id": "C-TXN-3002",
      "order": {
        "id": "C-ORD-9002",
        "date": "2025-11-09",
        "customer": {
          "id": "C-CUST-5002",
          "name": "Emily Clark",
          "email": "eclark@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-002",
          "description": "Tablet Case",
          "qty": 2,
          "price": {
            "amount": 19.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "PayPal",
        "total": 39.98
      }
    },
    {
      "id": "C-TXN-3003",
      "order": {
        "id": "C-ORD-9003",
        "date": "2025-11-10",
        "customer": {
          "id": "C-CUST-5003",
          "name": "Michael Brown",
          "email": "mbrown@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-003",
          "description": "HDMI Cable",
          "qty": -3,
          "price": {
            "amount": 8.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "CreditCard",
        "total": 26.97
      }
    },
    {
      "id": "C-TXN-3004",
      "order": {
        "id": "C-ORD-9004",
        "date": null,
        "customer": {
          "id": "C-CUST-5004",
          "name": "Laura Hill",
          "email": "lhill@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-004",
          "description": "USB Cable",
          "qty": 1,
          "price": {
            "amount": 5.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "CreditCard",
        "total": 5.99
      }
    },
    {
      "id": "C-TXN-3005",
      "order": {
        "id": null,
        "date": "2025-11-12",
        "customer": {
          "id": "C-CUST-5005",
          "name": "Tom Hardy",
          "email": "thardy@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-005",
          "description": "Webcam",
          "qty": 1,
          "price": {
            "amount": 49.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "CreditCard",
        "total": 49.99
      }
    },
    {
      "id": "C-TXN-3006",
      "order": {
        "id": "C-ORD-9006",
        "date": "2025-11-13",
        "customer": {
          "id": "C-CUST-5006",
          "name": "",
          "email": "noemail@"
        }
      },
      "items": [
        {
          "sku": "C-SKU-006",
          "description": "Monitor",
          "qty": 1,
          "price": {
            "amount": 199.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "CreditCard",
        "total": 199.99
      }
    },
    {
      "id": "C-TXN-3007",
      "order": {
        "id": "C-ORD-9007",
        "date": "2025-11-14",
        "customer": {
          "id": "C-CUST-5007",
          "name": "Sarah Lee",
          "email": "slee@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-007",
          "description": "Mouse Pad",
          "qty": 0,
          "price": {
            "amount": 9.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "CreditCard",
        "total": 0.0
      }
    },
    {
      "id": "C-TXN-3008",
      "order": {
        "id": "C-ORD-9008",
        "date": "2025-11-15",
        "customer": {
          "id": "C-CUST-9999",
          "name": "Unknown User",
          "email": "unknown@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-999",
          "description": "Unknown Product",
          "qty": 1,
          "price": {
            "amount": 0.0,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "PayPal",
        "total": 0.0
      }
    },
    {
      "id": "C-TXN-3009",
      "order": {
        "id": "C-ORD-9009",
        "date": "2025-11-16",
        "customer": {
          "id": "C-CUST-5008",
          "name": "Kevin Young",
          "email": "kyoung@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-008",
          "description": "Portable SSD",
          "qty": 1,
          "price": {
            "amount": 89.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "CreditCard",
        "total": 89.99
      }
    },
    {
      "id": "C-TXN-3010",
      "order": {
        "id": "C-ORD-9010",
        "date": "2025-11-16",
        "customer": {
          "id": "C-CUST-5009",
          "name": "Amy Wong",
          "email": "awong@example.com"
        }
      },
      "items": [
        {
          "sku": "C-SKU-009",
          "description": "Phone Stand",
          "qty": 2,
          "price": {
            "amount": 14.99,
            "currency": "USD"
          }
        }
      ],
      "payment": {
        "method": "PayPal",
        "total": 29.98
      }
    }
  ]
}$$);

CREATE OR REPLACE TABLE RAW.A_CUSTOMER (customer_id STRING,first_name STRING,last_name STRING,email STRING,loyalty_tier STRING,signup_source STRING,is_active STRING);
INSERT INTO RAW.A_CUSTOMER VALUES
('CUST-A-0001','John','Doe','john.doe@example.com','GOLD','Web','true'),
('CUST-A-0002','Jane','Smith','jane.smith@example.com','SILVER','MobileApp','true'),
('CUST-A-0003','Bob','Williams','bob.williams@example.com',NULL,'Referral','true'),
('CUST-A-0004',NULL,'Unknown',NULL,'BRONZE','Web','false'),
('CUST-A-0005','Chris','Evans','cevans@example','PLATINUM','Web','true'),
('CUST-A-0006','Emily','Clark','eclark@example.com','SILVER','MobileApp','true'),
('CUST-A-0007','Michael','Brown','mbrown@example.com','GOLD','Web','true'),
('CUST-A-0008','Laura','Hill','lhill@example.com',NULL,'Web','true'),
('CUST-A-0009','Tom','Hardy','thardy@example.com','BRONZE','Referral','true'),
('CUST-A-0010','Sarah','Lee','slee@example.com','GOLD','Web','true'),
('CUST-A-0011','Kevin','Young','kyoung@example.com',NULL,'MobileApp','true'),
('CUST-A-0012','Amy','Wong','awong@example.com','SILVER','Web','true'),
('CUST-A-0013','Daniel','Kim','dkim@example.com','GOLD','Web','true'),
('CUST-A-0014','Olivia','Green','ogreen@example.com','BRONZE','Referral','true'),
('CUST-A-0015','Henry','Adams',NULL,'SILVER','Web','true'),
('CUST-A-0016','Linda','Park','lpark@example.com','GOLD','MobileApp','true'),
('CUST-A-0017','George','Nguyen','gnguyen@example.com',NULL,'Web','true'),
('CUST-A-0018','Rachel','Stone','rstone@example.com','PLATINUM','Web','true'),
('CUST-A-0019','Jason','Wells','jwells@example.com','SILVER','Referral','true'),
('CUST-A-0020','Marcus','Reed','mreed@example.com','GOLD','Web','true'),
('CUST-A-0001','John','Doe','john.doe@example.com','GOLD','Web','true'),
('CUST-A-0033','Julia','Chen','jchen@@example..com','SILVER','Web','true'),
('CUST-A-0040',NULL,NULL,NULL,NULL,'false',NULL);
CREATE OR REPLACE TABLE RAW.A_ORDERS (order_id STRING,customer_id STRING,order_date STRING,order_status STRING,channel STRING);
INSERT INTO RAW.A_ORDERS VALUES
('ORD-5001','CUST-A-0001','2025-11-10','COMPLETED','Web'),
('ORD-5002','CUST-A-0002','2025-11-10','CANCELLED','Mobile'),
('ORD-5003','CUST-A-0003','2025-11-11','COMPLETED','Web'),
('ORD-5004','CUST-A-9999','2025-11-11','COMPLETED','Web'),
('ORD-5005','CUST-A-0004',NULL,'PENDING','Web'),
('ORD-5006','CUST-A-0005','2025-11-12','COMPLETED','Mobile'),
('ORD-5007','CUST-A-0006','2025-11-12','COMPLETED','Web'),
('ORD-5008','CUST-A-0007',NULL,'COMPLETED','Web'),
('ORD-5009','CUST-A-0008','2025-11-13','COMPLETED','Web'),
('ORD-5010','CUST-A-0009','2025-11-14','COMPLETED','Web'),
('ORD-5011','CUST-A-0010','2025-11-14','COMPLETED','Web'),
('ORD-5012','CUST-A-0011','2025-11-14','COMPLETED','Web'),
('ORD-5013','CUST-A-0012','2025-11-15','COMPLETED','Web'),
('ORD-5014','CUST-A-0013','2025-11-15','COMPLETED','Web'),
('ORD-5015','CUST-A-0014','2025-11-15','COMPLETED','Web'),
('ORD-5016','CUST-A-0015','2025-11-16','COMPLETED','Web'),
('ORD-5017','CUST-A-0016','2025-11-16','COMPLETED','Web'),
('ORD-5018','CUST-A-0001','2025-11-16','COMPLETED','Web'),
('ORD-5019','CUST-A-0017',NULL,'COMPLETED','Web'),
('ORD-5020','CUST-A-0018','2025-11-17','COMPLETED','Web'),
('ORD-5001','CUST-A-0001','2025-11-10','COMPLETED','Web');
CREATE OR REPLACE TABLE RAW.A_PRODUCTS (sku STRING,product_name STRING,category STRING,unit_price STRING,currency STRING,is_active STRING);
INSERT INTO RAW.A_PRODUCTS VALUES
('SKU-A-001','Wireless Mouse','Accessories','25.99','USD','true'),
('SKU-A-002','Keyboard','Accessories','45.50','USD','true'),
('SKU-A-003','USB-C Charger','Chargers','19.99','USD','true'),
('SKU-A-004','Screen Protector','Accessories','9.99','USD','true'),
('SKU-A-005','Gaming Headset','Audio','79.99','USD','false'),
('SKU-A-006','Portable SSD','Storage','89.99','USD','true'),
('SKU-A-007','HDMI Cable','Cables','8.99','USD','true'),
('SKU-A-008','USB Cable','Cables','5.99','USD','true'),
('SKU-A-009','Webcam','Electronics','49.99','USD','true'),
('SKU-A-010','Wireless Charger','Chargers','29.99','USD','true'),
('SKU-A-011','Mouse Pad','Accessories','-9.99','USD','true'),
('SKU-A-012','Bluetooth Keyboard','Accessories','39.99','USD','true'),
('SKU-A-013','Phone Stand','Accessories','14.99','USD','true'),
('SKU-A-014','USB Hub','Accessories','24.99','USD','true'),
('SKU-A-015','Desk Lamp','Home Office','34.99','USD','true'),
('SKU-A-016','Wireless Earbuds','Audio','59.99','USD','true'),
('SKU-A-017','Smartwatch Band','Accessories','12.99','USD','true'),
('SKU-A-018','Phone Case','Accessories','14.99','USD','true'),
('SKU-A-019','Bluetooth Tracker','Electronics','29.99','USD','true'),
('SKU-A-020','Desk Organizer','Home Office','19.99','USD','true'),
('SKU-A-003','USB-C Charger','Chargers','19.99','USD','true'),
('SKU-A-999','Unknown Product','Unknown','0.00','USD','false');
CREATE OR REPLACE TABLE RAW.C_CUSTOMER (customer_id STRING,customer_name STRING,email STRING,segment STRING,is_active STRING);
INSERT INTO RAW.C_CUSTOMER VALUES
('C-CUST-5001','Chris Evans','cevans@example.com','VIP','true'),
('C-CUST-5002','Emily Clark','eclark@example.com','REGULAR','true'),
('C-CUST-5003','Michael Brown','mbrown@example.com','REGULAR','true'),
('C-CUST-5004','Laura Hill','lhill@example.com','NEW','true'),
('C-CUST-5005','Tom Hardy','thardy@example.com','VIP','true'),
('C-CUST-5006',NULL,'noemail@','REGULAR','true'),
('C-CUST-5007','Sarah Lee','slee@example.com','REGULAR','true'),
('C-CUST-5008','Kevin Young','kyoung@example.com','REGULAR','true'),
('C-CUST-5009','Amy Wong','awong@example.com','REGULAR','true'),
('C-CUST-5010','Unknown User','unknown@example.com','UNKNOWN','false'),
('C-CUST-5011','Daniel Kim','dkim@example.com','VIP','true'),
('C-CUST-5012','Olivia Green','ogreen@example.com','REGULAR','true'),
('C-CUST-5013','Henry Adams',NULL,'REGULAR','true'),
('C-CUST-5014','Linda Park','lpark@example.com','VIP','true'),
('C-CUST-5015','George Nguyen','gnguyen@example.com','REGULAR','true'),
('C-CUST-5016','Rachel Stone','rstone@example.com','VIP','true'),
('C-CUST-5017','Jason Wells','jwells@example.com','REGULAR','true'),
('C-CUST-5018','Marcus Reed','mreed@example.com','VIP','true'),
('C-CUST-5019','Elena Foster','efoster@example.com','REGULAR','true'),
('C-CUST-5020','Julia Chen','jchen@@example..com','REGULAR','true'),
('C-CUST-5001','Chris Evans','cevans@example.com','VIP','true'),
('C-CUST-5099',NULL,NULL,NULL,'false');
CREATE OR REPLACE TABLE RAW.C_ORDERS (order_id STRING,customer_id STRING,order_date STRING,order_status STRING);
INSERT INTO RAW.C_ORDERS VALUES
('C-ORD-9001','C-CUST-5001','2025-11-08','COMPLETED'),
('C-ORD-9002','C-CUST-5002','2025-11-09','COMPLETED'),
('C-ORD-9003','C-CUST-5003','2025-11-10','COMPLETED'),
('C-ORD-9004','C-CUST-5004',NULL,'PENDING'),
('C-ORD-9005','C-CUST-5005','2025-11-12','COMPLETED'),
('C-ORD-9006','C-CUST-5006','2025-11-13','COMPLETED'),
('C-ORD-9007','C-CUST-5007','2025-11-14','COMPLETED'),
('C-ORD-9008','C-CUST-9999','2025-11-15','COMPLETED'),
('C-ORD-9009','C-CUST-5008','2025-11-16','COMPLETED'),
('C-ORD-9010','C-CUST-5009','2025-11-16','COMPLETED'),
('C-ORD-9011','C-CUST-5010','2025-11-17','COMPLETED'),
('C-ORD-9012','C-CUST-5011','2025-11-17','COMPLETED'),
('C-ORD-9013','C-CUST-5012','2025-11-18','COMPLETED'),
('C-ORD-9014','C-CUST-5013','2025-11-18','COMPLETED'),
('C-ORD-9015','C-CUST-5014','2025-11-18','COMPLETED'),
('C-ORD-9016','C-CUST-5015','2025-11-19','COMPLETED'),
('C-ORD-9017','C-CUST-5016','2025-11-19','COMPLETED'),
('C-ORD-9018','C-CUST-5001','2025-11-19','COMPLETED'),
('C-ORD-9019','C-CUST-5017',NULL,'COMPLETED'),
('C-ORD-9020','C-CUST-5018','2025-11-20','COMPLETED'),
('C-ORD-9001','C-CUST-5001','2025-11-08','COMPLETED');
CREATE OR REPLACE TABLE RAW.C_PRODUCTS (sku STRING,product_name STRING,category STRING,unit_price STRING,currency STRING,is_active STRING);
INSERT INTO RAW.C_PRODUCTS VALUES
('C-SKU-001','Smartwatch','Electronics','149.99','USD','true'),
('C-SKU-002','Tablet Case','Accessories','19.99','USD','true'),
('C-SKU-003','HDMI Cable','Cables','8.99','USD','true'),
('C-SKU-004','USB Cable','Cables','5.99','USD','true'),
('C-SKU-005','Webcam','Electronics','49.99','USD','true'),
('C-SKU-006','Monitor','Electronics','199.99','USD','true'),
('C-SKU-007','Mouse Pad','Accessories','9.99','USD','true'),
('C-SKU-008','Portable SSD','Storage','89.99','USD','true'),
('C-SKU-009','Phone Stand','Accessories','14.99','USD','true'),
('C-SKU-010','Desk Lamp','Home Office','34.99','USD','true'),
('C-SKU-011','Wireless Earbuds','Audio','59.99','USD','true'),
('C-SKU-012','Smartwatch Band','Accessories','12.99','USD','true'),
('C-SKU-013','Phone Case','Accessories','14.99','USD','true'),
('C-SKU-014','Bluetooth Tracker','Electronics','29.99','USD','true'),
('C-SKU-015','Desk Organizer','Home Office','19.99','USD','true'),
('C-SKU-003','HDMI Cable','Cables','8.99','USD','true'),
('C-SKU-999','Unknown Product','Unknown','0.00','USD','false'),
('C-SKU-011','Wireless Earbuds','Audio','-59.99','USD','true');
CREATE OR REPLACE TABLE RAW.C_PAYMENTS (payment_id STRING,order_id STRING,payment_method STRING,amount STRING,currency STRING,status STRING);
INSERT INTO RAW.C_PAYMENTS VALUES
('PAY-C-0001','C-ORD-9001','CreditCard','149.99','USD','SETTLED'),
('PAY-C-0002','C-ORD-9002','PayPal','39.98','USD','SETTLED'),
('PAY-C-0003','C-ORD-9003','CreditCard','26.97','USD','SETTLED'),
('PAY-C-0004','C-ORD-9004','CreditCard','5.99','USD','FAILED'),
('PAY-C-0005','C-ORD-9005','CreditCard','-10.00','USD','REFUNDED'),
('PAY-C-0006','C-ORD-9006','PayPal','199.99','USD','SETTLED'),
('PAY-C-0007','C-ORD-9007','CreditCard','0.00','USD','SETTLED'),
('PAY-C-0008','C-ORD-9008','PayPal','0.00','USD','SETTLED'),
('PAY-C-0009','C-ORD-9009','CreditCard','89.99','USD','SETTLED'),
('PAY-C-0010','C-ORD-9010','PayPal','29.98','USD','SETTLED'),
('PAY-C-0011','C-ORD-9011','CreditCard','49.99','USD','SETTLED'),
('PAY-C-0012','C-ORD-9012','CreditCard','24.99','USD','SETTLED'),
('PAY-C-0013','C-ORD-9013','PayPal','14.99','USD','SETTLED'),
('PAY-C-0014','C-ORD-9014','PayPal','24.99','USD','SETTLED'),
('PAY-C-0015','C-ORD-9015','CreditCard','69.98','USD','SETTLED'),
('PAY-C-0016','C-ORD-9016','PayPal','59.99','USD','SETTLED'),
('PAY-C-0017','C-ORD-9017','CreditCard','-49.99','USD','REFUNDED'),
('PAY-C-0018','C-ORD-9018','CreditCard','25.98','USD','SETTLED'),
('PAY-C-0019','C-ORD-9019','PayPal','44.97','USD','SETTLED'),
('PAY-C-0020','C-ORD-9020','CreditCard','29.99','USD','SETTLED'),
('PAY-C-0001','C-ORD-9001','CreditCard','149.99','USD','SETTLED');

-- ==========================================================================
-- 2. STAGE : flatten -> cast -> validate -> dedupe -> normalize
-- ==========================================================================
USE SCHEMA FIN_INGEST.STAGE;

-- 2a. Client A: explode XML to one row per <Item>, keeping raw node for audit.
CREATE OR REPLACE TABLE STAGE.A_TXN_ITEMS AS
WITH txn AS (
  SELECT x.src_file, t.value AS txn_node
  FROM RAW.CLIENTA_XML x,
       LATERAL FLATTEN(input => x.doc:"$") t
  WHERE GET(t.value,'@')::STRING = 'Transaction'
)
SELECT
  'CLIENT_A'                                                                            AS source_system,
  txn.src_file,
  NULLIF(TRIM(XMLGET(txn_node,'TransactionID'):"$"::STRING),'')                         AS transaction_id,
  NULLIF(TRIM(XMLGET(XMLGET(txn_node,'Order'),'OrderID'):"$"::STRING),'')               AS order_id,
  TRY_TO_DATE(NULLIF(TRIM(XMLGET(XMLGET(txn_node,'Order'),'OrderDate'):"$"::STRING),''))AS order_date,
  NULLIF(TRIM(XMLGET(XMLGET(XMLGET(txn_node,'Order'),'Customer'),'CustomerID'):"$"::STRING),'') AS customer_id,
  NULLIF(TRIM(XMLGET(XMLGET(XMLGET(txn_node,'Order'),'Customer'),'Email'):"$"::STRING),'')      AS customer_email,
  NULLIF(TRIM(XMLGET(item.value,'SKU'):"$"::STRING),'')                                 AS sku,
  NULLIF(TRIM(XMLGET(item.value,'Description'):"$"::STRING),'')                         AS description,
  TRY_TO_NUMBER(XMLGET(item.value,'Quantity'):"$"::STRING)                              AS quantity,
  TRY_TO_DECIMAL(XMLGET(item.value,'UnitPrice'):"$"::STRING,18,2)                       AS unit_price,
  COALESCE(GET(XMLGET(item.value,'UnitPrice'),'@currency')::STRING,'USD')               AS currency,
  NULLIF(TRIM(XMLGET(XMLGET(txn_node,'Payment'),'Method'):"$"::STRING),'')              AS payment_method,
  TRY_TO_DECIMAL(XMLGET(XMLGET(txn_node,'Payment'),'Amount'):"$"::STRING,18,2)          AS payment_amount,
  TO_VARIANT(txn_node)                                                                  AS raw_record
FROM txn,
     LATERAL FLATTEN(input => XMLGET(txn.txn_node,'Items'):"$", outer => TRUE) item;

-- 2b. Client C: explode JSON to one row per item, keeping raw record for audit.
CREATE OR REPLACE TABLE STAGE.C_TXN_ITEMS AS
SELECT
  'CLIENT_C'                                           AS source_system,
  j.src_file,
  t.value:id::STRING                                  AS transaction_id,
  t.value:order:id::STRING                            AS order_id,
  TRY_TO_DATE(t.value:order:date::STRING)             AS order_date,
  t.value:order:customer:id::STRING                  AS customer_id,
  t.value:order:customer:email::STRING               AS customer_email,
  i.value:sku::STRING                                 AS sku,
  i.value:description::STRING                         AS description,
  TRY_TO_NUMBER(i.value:qty::STRING)                 AS quantity,
  TRY_TO_DECIMAL(i.value:price:amount::STRING,18,2)  AS unit_price,
  COALESCE(i.value:price:currency::STRING,'USD')     AS currency,
  t.value:payment:method::STRING                     AS payment_method,
  TRY_TO_DECIMAL(t.value:payment:total::STRING,18,2) AS payment_amount,
  t.value                                             AS raw_record
FROM RAW.CLIENTC_JSON j,
     LATERAL FLATTEN(input => j.doc:transactions)            t,
     LATERAL FLATTEN(input => t.value:items, outer => TRUE)  i;

-- 2c. NORMALIZED, deduplicated transaction lines from both clients.
--     Email regex (Regla 4); QUALIFY for dedup over the natural line grain.
CREATE OR REPLACE TABLE STAGE.TRANSACTION_LINES AS
WITH unioned AS (
  SELECT *, CURRENT_TIMESTAMP() AS load_timestamp FROM STAGE.A_TXN_ITEMS
  UNION ALL
  SELECT *, CURRENT_TIMESTAMP() AS load_timestamp FROM STAGE.C_TXN_ITEMS
)
SELECT
  source_system, transaction_id, order_id, order_date,
  customer_id, customer_email, sku, description,
  quantity, unit_price,
  CASE WHEN quantity > 0 AND unit_price >= 0 THEN quantity * unit_price END AS line_amount,
  currency, payment_method, payment_amount, raw_record, load_timestamp,
  -- ---- data-quality rule flags --------------------------------------------
  (transaction_id IS NULL)                              AS dq_missing_txn_id,    -- Regla 1
  (order_id       IS NULL)                              AS dq_missing_order_id,  -- Regla 2
  (order_date     IS NULL)                              AS dq_missing_date,
  (quantity IS NULL OR quantity <= 0)                   AS dq_bad_quantity,      -- Regla 3
  (unit_price IS NULL OR unit_price < 0)                AS dq_bad_price,
  (customer_email IS NULL
     OR NOT REGEXP_LIKE(customer_email,
        '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')) AS dq_bad_email   -- Regla 4
FROM unioned
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY source_system, transaction_id, sku, quantity, unit_price
  ORDER BY load_timestamp DESC
) = 1;   -- collapse exact duplicate lines (e.g. TXN-1001 / C-TXN-3001)

-- ==========================================================================
-- 3. QUARANTINE : divert hard failures with reason + raw record
-- ==========================================================================
CREATE OR REPLACE TABLE FIN_INGEST.QUARANTINE.INVALID_TRANSACTIONS (
  transaction_id        STRING,
  source_system         STRING,
  error_reason          STRING,
  raw_record            VARIANT,
  quarantine_timestamp  TIMESTAMP_NTZ
);

INSERT INTO FIN_INGEST.QUARANTINE.INVALID_TRANSACTIONS
SELECT
  transaction_id, source_system,
  ARRAY_TO_STRING(ARRAY_CONSTRUCT_COMPACT(
    IFF(dq_missing_txn_id ,'MISSING_TRANSACTION_ID',NULL),
    IFF(dq_missing_order_id,'MISSING_ORDER_ID'     ,NULL),
    IFF(dq_bad_quantity   ,'INVALID_QUANTITY'      ,NULL),
    IFF(dq_bad_price      ,'INVALID_PRICE'         ,NULL)
  ), '; ')                                       AS error_reason,
  raw_record,
  CURRENT_TIMESTAMP()
FROM STAGE.TRANSACTION_LINES
WHERE dq_missing_txn_id OR dq_missing_order_id OR dq_bad_quantity OR dq_bad_price;

-- ==========================================================================
-- 4. CANON : conformed star + per-transaction summary + DQ metrics
-- ==========================================================================
USE SCHEMA FIN_INGEST.CANON;

-- 4a. Conformed dimensions (deduped, client-namespaced surrogate keys) ------
CREATE OR REPLACE TABLE CANON.DIM_CUSTOMER AS
SELECT source_system||'|'||customer_id AS customer_sk,
       source_system, customer_id, customer_name, email, segment, is_active, email_is_valid
FROM (
  SELECT 'CLIENT_A' AS source_system, customer_id,
         NULLIF(TRIM(first_name||' '||last_name),'') AS customer_name,
         email, loyalty_tier AS segment, TRY_TO_BOOLEAN(is_active) AS is_active,
         NOT (email IS NULL OR NOT REGEXP_LIKE(email,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')) AS email_is_valid
  FROM RAW.A_CUSTOMER WHERE customer_id IS NOT NULL
  UNION ALL
  SELECT 'CLIENT_C', customer_id, NULLIF(TRIM(customer_name),''), email, segment,
         TRY_TO_BOOLEAN(is_active),
         NOT (email IS NULL OR NOT REGEXP_LIKE(email,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'))
  FROM RAW.C_CUSTOMER WHERE customer_id IS NOT NULL
)
QUALIFY ROW_NUMBER() OVER (PARTITION BY source_system, customer_id ORDER BY customer_name NULLS LAST) = 1;

CREATE OR REPLACE TABLE CANON.DIM_PRODUCT AS
SELECT source_system||'|'||sku AS product_sk,
       source_system, sku, product_name, category, unit_price, currency, is_active, price_is_negative
FROM (
  SELECT 'CLIENT_A' AS source_system, sku, product_name, category,
         TRY_TO_DECIMAL(unit_price,18,2) AS unit_price, currency,
         TRY_TO_BOOLEAN(is_active) AS is_active,
         (TRY_TO_DECIMAL(unit_price,18,2) < 0) AS price_is_negative
  FROM RAW.A_PRODUCTS WHERE sku IS NOT NULL
  UNION ALL
  SELECT 'CLIENT_C', sku, product_name, category,
         TRY_TO_DECIMAL(unit_price,18,2), currency, TRY_TO_BOOLEAN(is_active),
         (TRY_TO_DECIMAL(unit_price,18,2) < 0)
  FROM RAW.C_PRODUCTS WHERE sku IS NOT NULL
)
QUALIFY ROW_NUMBER() OVER (PARTITION BY source_system, sku ORDER BY unit_price DESC NULLS LAST) = 1;

-- 4b. Fact at ITEM-LINE grain (the robust grain: preserves per-SKU detail) --
CREATE OR REPLACE TABLE CANON.FCT_TRANSACTION_LINE AS
SELECT
  SHA2(source_system||COALESCE(transaction_id,'')||COALESCE(sku,'')||
       COALESCE(quantity::STRING,'')||COALESCE(unit_price::STRING,'')) AS txn_line_sk,
  source_system, transaction_id, order_id, order_date,
  source_system||'|'||customer_id AS customer_sk,
  source_system||'|'||sku         AS product_sk,
  quantity, unit_price, line_amount, currency,
  payment_method, payment_amount,
  OBJECT_CONSTRUCT('missing_txn_id',dq_missing_txn_id,'missing_order_id',dq_missing_order_id,
                   'missing_date',dq_missing_date,'bad_quantity',dq_bad_quantity,
                   'bad_price',dq_bad_price,'bad_email',dq_bad_email) AS dq_flags
FROM STAGE.TRANSACTION_LINES
WHERE NOT (dq_missing_txn_id OR dq_missing_order_id OR dq_bad_quantity OR dq_bad_price);  -- clean rows only

-- 4c. Per-transaction aggregated view (the "flat" grain on top of the lines)
CREATE OR REPLACE VIEW CANON.VW_TRANSACTION_SUMMARY AS
SELECT
  source_system, transaction_id, order_id, order_date, customer_sk,
  COUNT(*)                       AS line_count,
  SUM(quantity)                  AS total_quantity,
  SUM(line_amount)               AS total_line_amount,
  MAX(payment_method)            AS payment_method,
  MAX(payment_amount)            AS payment_amount,
  ROUND(MAX(payment_amount) - SUM(line_amount),2) AS payment_vs_lines_diff
FROM CANON.FCT_TRANSACTION_LINE
GROUP BY source_system, transaction_id, order_id, order_date, customer_sk;

-- 4d. Data-quality metrics view (one-stop dashboard) -----------------------
CREATE OR REPLACE VIEW CANON.VW_DATA_QUALITY_METRICS AS
WITH staged AS (SELECT * FROM STAGE.TRANSACTION_LINES)
SELECT
  (SELECT COUNT(*) FROM staged)                                           AS staged_lines,
  (SELECT COUNT(*) FROM CANON.FCT_TRANSACTION_LINE)                       AS clean_lines,
  (SELECT COUNT(*) FROM FIN_INGEST.QUARANTINE.INVALID_TRANSACTIONS)       AS quarantined_lines,
  (SELECT COUNT(DISTINCT transaction_id) FROM CANON.FCT_TRANSACTION_LINE) AS unique_transactions,
  (SELECT COUNT(*) FROM staged WHERE dq_bad_quantity)                     AS invalid_quantities,
  (SELECT COUNT(*) FROM staged WHERE dq_bad_price)                        AS invalid_prices,
  (SELECT COUNT(*) FROM staged WHERE dq_bad_email)                        AS invalid_emails,
  (SELECT COUNT(*) FROM CANON.DIM_CUSTOMER WHERE NOT email_is_valid)      AS customers_bad_email,
  (SELECT COUNT(*) FROM CANON.DIM_PRODUCT  WHERE price_is_negative)       AS products_negative_price;

-- ==========================================================================
-- 5. VERIFICATION QUERIES  (run and inspect each result)
-- ==========================================================================

-- 5.1 Quality dashboard
SELECT * FROM CANON.VW_DATA_QUALITY_METRICS;

-- 5.2 Dedup proof: duplicated txns survive once per line
SELECT source_system, transaction_id, COUNT(*) AS lines
FROM CANON.FCT_TRANSACTION_LINE
WHERE transaction_id IN ('TXN-1001','C-TXN-3001')
GROUP BY 1,2;

-- 5.3 Quarantine contents with reasons
SELECT transaction_id, source_system, error_reason, quarantine_timestamp
FROM FIN_INGEST.QUARANTINE.INVALID_TRANSACTIONS
ORDER BY source_system, transaction_id;

-- 5.4 Per-transaction summary (note payment vs. line-sum differences)
SELECT * FROM CANON.VW_TRANSACTION_SUMMARY ORDER BY source_system, transaction_id;

-- 5.5 Orphan FK check: orders pointing to non-existent customers
SELECT 'CLIENT_A' src, o.order_id, o.customer_id
FROM RAW.A_ORDERS o
LEFT JOIN CANON.DIM_CUSTOMER c ON c.source_system='CLIENT_A' AND c.customer_id=o.customer_id
WHERE o.order_id IS NOT NULL AND c.customer_sk IS NULL
UNION ALL
SELECT 'CLIENT_C', o.order_id, o.customer_id
FROM RAW.C_ORDERS o
LEFT JOIN CANON.DIM_CUSTOMER c ON c.source_system='CLIENT_C' AND c.customer_id=o.customer_id
WHERE o.order_id IS NOT NULL AND c.customer_sk IS NULL;

-- 5.6 Invalid emails surfaced but retained in the dimension
SELECT source_system, customer_id, email FROM CANON.DIM_CUSTOMER WHERE NOT email_is_valid;
