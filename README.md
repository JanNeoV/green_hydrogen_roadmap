# Green Hydrogen Cost Calculation Power BI Report

## Overview

This project presents a Power BI Report that illustrates a path-based approach to estimate potential costs for green hydrogen. The report combines various data sources and methodologies to provide a comprehensive analysis.

[View Power BI Report](https://app.powerbi.com/view?r=eyJrIjoiZDYyMWZmMjMtN2ZmNi00ZTA5LThlY2MtNjk3MDkxOTIxMjM5IiwidCI6IjI5ODAzN2JlLTdhZDgtNGM4My04MGYzLTRmMDQ1NGEwY2ZjZCJ9)

## Project Setup and Data Processing

### Initial Data Handling

The project initially relied on local CSV files for data. To effectively analyze and structure this data, I employed R within Power BI Desktop, which allowed for the derivation of essential dimensions directly from the datasets.

### API Integration with ENTSO-E Transparency Platform

One of the critical steps was creating an API to interface with the ENTSO-E Transparency Platform. However, initial attempts to process this data using R, Python, and Power Query faced significant performance issues.

### Path-Based Algorithm and Performance Challenges

A central component of the analysis was a path-based algorithm, essential for calculating all potential cost combinations for green hydrogen. This required the use of a crossjoin-function, but again, performance issues were encountered, especially with Power Query, which showed the poorest performance.

### Model Refactoring for Enhanced Performance

To overcome these challenges, I refactored the entire model:

- **API with R for Data Upload**: I developed an R-based API to upload all relevant data to a local PostgreSQL database. This step was crucial for enhancing data processing efficiency.
- **SQL for Data Processing**: Where possible, I translated R processing steps into SQL, which significantly improved the performance and reduced the model size by more than half.
- **Minimizing Power Query Usage**: By leveraging SQL, I was able to eliminate most steps that were previously performed in Power Query, further boosting the performance.

### Balancing Real-Time Data and Performance

The model aims to handle near real-time market data while maintaining high performance. However, it also integrates data from local sources, such as academic papers on energy economics. This mix presents unique challenges:

- **Direct Mode vs. Import Mode**: Ideally, the model would use Import Mode for performance reasons. However, this means that the data is not real-time but depends on the manual refresh or scheduled refresh. This makes this a perfect case study for **Microsoft Fabric** and more specifically Direct Lake which combines the best of both worlds: high performance and near real-time data.
