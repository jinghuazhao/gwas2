import argparse
import os
import pandas as pd
import sqlite3

# mapping chromosome string (incluing 01-09, 23, and X) and correct string
CHROM_MAPPING_STR = dict([(str(i), str(i)) for i in range(1, 23)] +
                         [('0' + str(i), str(i)) for i in range(1, 10)] +
                         [('X', 'X')])
csvfile=os.environ['csvfile']

def main(args):
    conn = sqlite3.connect(args.bgi)
    c = conn.cursor()
    df = pd.read_csv("Variant.csv")
    df.to_sql("Variant", conn, if_exists="replace", index=False)
    df.to_csv(csvfile,index=False)
    conn.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--bgi', type=str, required=True)
    args = parser.parse_args()
    main(args)
