---
layout: post
title: "Spark resampling"
tags:
    - python
    - notebook
author: Rok Mihevc
---
Working with time dependat data in Spark I often need to aggregate data on arbitrary time intervals. As there is no handy function to that I (with help of [equialgo](https://github.com/equialgo)) wrote a helper function that will resample a time series column to intervals of arbitrary length, that can then be used for aggregation operations. 

Let's look at the function first:
{% highlight python %}

def resample(column, agg_interval=900, time_format='yyyy-MM-dd HH:mm:ss'):
    if type(column)==str:
        column = F.col(column)

    # Convert the timestamp to unix timestamp format.
    # Unix timestamp = number of seconds since 00:00:00 UTC, 1 January 1970.
    col_ut =  F.unix_timestamp(column, format=time_format)

    # Divide the time into dicrete intervals, by rounding. 
    col_ut_agg =  F.floor(col_ut / agg_interval) * agg_interval  

    # Convert to and return a human readable timestamp
    return F.from_unixtime(col_ut_agg)
{% endhighlight %}

To give an example of use, let's create a sample timestamped dataframe:

**In [1]:**
{% highlight python %}
df = sqlContext.createDataFrame(d, ['dt','ip','email_provider'])
df.show(5)
{% endhighlight %}
**Out [1]**

    +-------------------+---------------+--------------+
    |                 dt|             ip|email_provider|
    +-------------------+---------------+--------------+
    |2016-01-20 17:08:24|  76.60.136.211|     yahoo.com|
    |2016-01-20 17:01:05| 36.196.144.103|     gmail.com|
    |2016-01-20 17:56:08| 33.243.151.184|   hotmail.com|
    |2016-01-20 17:25:36|  174.92.55.167|   hotmail.com|
    |2016-01-20 17:01:34|229.223.121.197|     gmail.com|
    +-------------------+---------------+--------------+
    only showing top 5 rows

We now use the resample function to resample our data to 15 minutes intervals (or rather 900 seconds):

**In [2]:**

{% highlight python %}
df = df.withColumn('dt_resampled', resample(df.dt, agg_interval=900))
df.show(5)
{% endhighlight %}

**Out [3]:**

    +-------------------+---------------+--------------+-------------------+
    |                 dt|             ip|email_provider|       dt_resampled|
    +-------------------+---------------+--------------+-------------------+
    |2016-01-20 17:08:24|  76.60.136.211|     yahoo.com|2016-01-20 17:00:00|
    |2016-01-20 17:01:05| 36.196.144.103|     gmail.com|2016-01-20 17:00:00|
    |2016-01-20 17:56:08| 33.243.151.184|   hotmail.com|2016-01-20 17:45:00|
    |2016-01-20 17:25:36|  174.92.55.167|   hotmail.com|2016-01-20 17:15:00|
    |2016-01-20 17:01:34|229.223.121.197|     gmail.com|2016-01-20 17:00:00|
    +-------------------+---------------+--------------+-------------------+
    only showing top 5 rows

We now use the new 'dt_resampled' column to group rows by intervals and email providers, and the aggregate the resulting groups by counting rows of groups.

**In [4]:**

{% highlight python %}
df_resampled = df.groupBy('dt_resampled', 'email_provider').count()
df_resampled.show(5)
{% endhighlight %}

**Out [4]:**

    +-------------------+--------------+-----+
    |               time|email_provider|count|
    +-------------------+--------------+-----+
    |2016-01-20 16:30:00|   hotmail.com|   31|
    |2016-01-20 16:30:00|     gmail.com|   28|
    |2016-01-20 16:45:00|   hotmail.com|   17|
    |2016-01-20 16:45:00|     gmail.com|   12|
    |2016-01-20 16:00:00|     yahoo.com|   39|
    +-------------------+--------------+-----+
    only showing top 5 rows
    
The data was resampled and aggregated, only thing left is to plot it. We move the aggregated Dataframe to Pandas, pivot it around the 'email_provider' column and finally plot the counts in time:

**In [5]:**

{% highlight python %}
df_resampled.toPandas() \
    .pivot(index='dt_resampled', columns='email_provider', values='count') \
    .plot(figsize=[14,5], title='Count emails per 15 minute interval')
{% endhighlight %}

**Out [5]:**
![png]({{ site.baseurl }}/notebooks/2016-01-20-Spark-resampling_files/2016-01-20-Spark-resampling_7_1.png)

As shown this resampling can be easy and fast in Spark using a helper function. The presented function will work for from microsecond- to century-long intervals. The one downside would be that leap years will make time stamps over long periods look less nice and solving for that would make the proposed function much more complicated as you can imagine by observing gregorian calendar time shifting:

![svg]({{ site.baseurl }}/notebooks/2016-01-20-Spark-resampling_files/Gregoriancalendarleap_solstice.svg)
