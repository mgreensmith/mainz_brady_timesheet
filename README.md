## Mainz Brady Group Timesheet

As a [virtuous programmer](http://threevirtues.com/), I am way too lazy to manually fill out and submit a timesheet every week, especially when my computer could easily handle this tedious chore without any intervention or action required on my part.

This implementation of an automated PDF filler is specific to the timesheet of my current agency, the [Mainz Brady Group](http://mainzbradygroup.com/), but could be (relatively) easily modified to fill out and email any PDF form.

## Installation

1. Clone me and `bundle install`
2. Create `config/config.yaml` by copying `config.yaml.default` and modifying as necessary.
3. Add an image of your signature to `/templates` and modify the `employee_signature_image` attribute in the config file accordingly. My signature image is 157x49 px, you may need to modify the `mbg_template.yaml` anchor points for the signature to align yours correctly if your dimensions differ.


##Usage

```
      Timesheet fills out and optionally sends a weekly timesheet to Mainz Brady.
      It defaults to the current week, where a week begins on Monday.
      Usage: timesheet [--send] [--uselast | (--weekof, -[mtwhfsu] <hours>)]
     --mon, -m <f>:   Monday hours worked (default: 8.0)
     --tue, -t <f>:   Tuesday hours worked (default: 8.0)
     --wed, -w <f>:   Wednesday hours worked (default: 8.0)
     --thu, -h <f>:   Thursday hours worked (default: 8.0)
     --fri, -f <f>:   Friday hours worked (default: 8.0)
     --sat, -s <f>:   Saturday hours worked (default: 0.0)
     --sun, -u <f>:   Sunday hours worked (default: 0.0)
  --weekof, -e <s>:   Generate timesheet for week that includes yyyy-mm-dd
    --lastweek, -l:   Generate timesheet for last week
     --uselast, -a:   Use saved data from last successful run, ignores (weekof,lastweek,mtwhfsu)
        --send, -n:   Sends the generated PDF via email
     --version, -v:   Print version and exit
        --help, -p:   Show this message
```

##Notes

I've experienced some openssl issues when trying to send mail via gmail under anything but system ruby (1.8.7) on my mac. YMMV.

##TODO

- When an hours-worked override is provided on the commandline, we should change the start and end time values accordingly.
