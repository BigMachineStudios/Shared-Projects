Experiments in data analysis, deep learning, computer vision, and other data related tasks

Project #1 - Stroke Data Analysis A few months ago, my younger brother suffered a major hemorrhagic stroke. This tragic event motivated me to look into possible contributing factors.

strokeanalysis.ipynb is a Jupyter Notebook that analyzes patient stroke data and looks for correlated conditions.

I begin by performing a simple single variable correlation. The results show the strongest correlation with age: Correlations with 'stroke' column:

|                   | stroke     |
|:------------------|:-----------|
| stroke            | 1          |
| age               | 0.245257   |
| heart_disease     | 0.134914   |
| avg_glucose_level | 0.131945   |
| hypertension      | 0.127904   |
| ever_married      | 0.10834    |
| bmi               | 0.0389466  |
| smoking_status    | 0.0281227  |
| Residence_type    | 0.015458   |
| gender            | 0.00892887 |
| id                | 0.00638817 |
| work_type         | -0.0323161 |

Heart disease, glucose level, and hypertension also correlate relatively highly.

I then perform multivariate correlation to see if multiple conditions work together to make a stronger correlation.

I apply 3 different methods: 
Logistic Regression 
Random Forest Feature Importance Analysis 
Multivariate Cluster Analysis (K-Means)

The results are plotted in the file.

Interpretation of the Cluster Analysis:

Cluster 2 — Highest Stroke Rate (0.17029) Average Age: 68.2 (oldest) Heart Disease: 100% have it (heart_disease = 1) Hypertension: ~23% Married: 88% High Glucose: 136.8 BMI: 30.1

Conclusion: Older patients with heart disease, moderate hypertension, and elevated glucose and BMI have the highest stroke rate. This cluster supports known risk factors: age, heart disease, hypertension, and high glucose/BMI.

Cluster 0 — Second Highest Stroke Rate (0.12212) Average Age: 61 Hypertension: 100% Heart Disease: 0% Married: 90% High BMI: 32.9
Conclusion: Stroke risk is high even without heart disease if hypertension, age, and BMI are elevated.

Clusters 1 & 5 — Very Low Stroke Rates (~0.01) Average Age: ~28 Hypertension/Heart Disease: 0% Not Married
Conclusion: Young, healthy individuals with no comorbidities are at minimal risk of stroke.

Cluster 8 — Young Children (Age ~7) — Lowest Stroke Rate (0.00295) No risk factors present BMI: 20 Smoking: Near 0 Work Type: 3.98 (likely children/unemployed category)
Conclusion: Expected: Children have virtually no stroke risk.

Clusters 3, 6, 7 — Middle-Aged Adults (Age 50–52) Stroke Rate: ~0.03–0.045 Hypertension/Heart Disease: None BMI: 29–30
Conclusion: Middle-aged adults without major comorbidities show a modest stroke risk, rising slightly with BMI and age.

General Conclusions on Stroke Risk
    1. Age is the strongest driver of stroke risk, especially beyond 60.
    2. Heart disease, hypertension, and high glucose/BMI strongly correlate with higher stroke rates.
    3. Young people (under 30) with no comorbidities have negligible stroke risk.
    4. Marital status (proxy for age/lifestyle) seems to trend with stroke incidence but is likely not causal.
    5. Clusters with multiple co-occurring risk factors (e.g., Cluster 2) have compounded stroke risk.
    
The high glucose factor was something I was unaware of and is confirmed in this research paper from the NIH.
https://pmc.ncbi.nlm.nih.gov/articles/PMC3329666/


Project #2 SQL queries of a relational database for an online digital music store

I only have two queries so far. I made the first one extra complicated so that it would require touching/joning multiple tables. The second is a work in progress because I find it rather boring, although I can imagine it being a typical task for hounding customers. The files are: Chinook_MySql.sql - this builds the database Chinook Queries.sql - the queries I have done so far...I'm still a little slow with this stuff until it becomes a bit more natural.


Project #3 Fetch live data from an online crypto coin reporting service and compile the data into a table for analysis and plotting.

This grew out of the desire to try something that worked with live data, combined python and sql, and made use of triggers and/or events. The problem made me think about hardware polling vs interrupt driven system communications and the trade-offs of each. From what I can tell, the closest things to a hardware interrupt are SQL triggers and signals in PostgreSQL. However, for the scope of this project, a simple timed event likely suffices. I may test them both.

This will use python as the framework for pulling the data in, pandas to structure the data, and SQLAlchemy to facilitate running SQL within the python script. The source for the data is yahoo finance. I'm currently using crypto data rather than stocks because they trade 24/7.

The current plan is as follows:
    1. Establish the SQLAlchemy engine connection to MySQL on my localhost.
    2. Fetch the current yfinance price and volume data for the day up to that point in time for one or more crypto coins.
    3. Create a pandas dataframe to load the data into.
    4. Use the SQLAlchemy engine to run SQL analysis operations.
    5. Continue to fetch live data from yfinance at some predetermined rate (30s to a minute)
    6. Append the live data into the table.
    7. Create an SQL event or trigger that runs an updated analysis utilizing the new data (most likely a weighted moving average and/or VWAP.
    8. Create a graph of the data.
    
Some of this working already in a Jupyter notebook and I'm working through issues getting the SQLAlchemy connection to connect. I read a few things regarding avoiding the use of SQL triggers and I am investigating that further. I have installed Docker on my system as it may help with these sorts of tasks. I need to due a system reboot to complete the install but I'm not prepared to take that action yet (many things I don't want to shut down right now). With a little luck, I'll have all this stuff figured out within the next 24hrs. It's a lot to take on and it’s all very new to me. But I shall persevere!!!



