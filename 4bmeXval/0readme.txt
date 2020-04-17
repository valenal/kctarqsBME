The files in this folder were created by the function getBmeXval.m. 
See help estBME.m for an explanation of the file naming scheme. 

import dask.dataframe as dd
df = dd.read_csv('./*eks*csv').compute()
scn  =  df["SCN"].str.split("_", n = 4, expand = True)
df['eks'] = scn[4]
df['tave'] = scn[1]

import dask.dataframe as dd
df = dd.read_csv('./*csv').compute()
scn  =  df["SCN"].str.split("_", n = 4, expand = True)
df['GO'] = scn[3]
df['tave'] = scn[1]
