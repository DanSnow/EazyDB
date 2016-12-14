SPEC
====

## Commands ##

- create:
  > Usage: cretae \<store path\> \<name\>  
  > Desc: Initialize a database structure at \<store path\>
- rput:
  > Usage: rput <record>
- fput:
  > Usage: fput <file path>
- rget:
  > Usage rget <rid>
- fget:
- rupdate:


## Directory Structure ##

```
database/
  - config
  - rdbfile
  - deletelist
  - index
```

- config:
  * Index/Search behavior
  * Memory usage limit
  * Dictionary: For index
  * Hash table
- rdbfile:
  * Path to store record
  * Deleted mark / Bitmap -> Deleted filter
- deletemap:
  * Bitmap for deleted mark
- index:
  * index file

## Implement detail ##

### Delete ###
- Use delete mark first, filter before output
- Purge deleted record regularly

## Index ##
- Key to id map
  * Original key
  * Hash key

