## AWS SWF Ruby Sample

[Documentation](http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-about-workflows.html)


[Tutorial of SWF-SNS](http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-sns-tutorial-running-the-workflow.html)


### Run

```
ruby swf_sns_workflow.rb 
```

Should show:

```
Amazon SWF Example
------------------

Start the activity worker, preferably in a separate command-line window, with
the following command:

> ruby swf_sns_activities.rb 87097e76-7c0c-41c7-817b-92527bb0ea85-activities

You can copy & paste it if you like, just don't copy the '>' character.

Press return when you're ready...  
```

Open **a new terminal**, type:

```
ruby swf_sns_activities.rb 87097e76-7c0c-41c7-817b-92527bb0ea85-activities
```


