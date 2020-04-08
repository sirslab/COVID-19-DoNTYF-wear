```flow
st=>start: Begin hand selection screen
e=>end: End hand selection screen
cond1=>condition: Wear watch on right hand?
saveHand=>operation: Save info for later
para=>parallel: parallel tasks
read=>operation: read magnetometer
norm=>operation: calculate norm
buffer=>operation: save in buffer
avg=>operation: buffer avg = offset




st->para
para(path1, bottom)->cond1(top)
para(path2,right)->read->norm->buffer->avg->e
cond1(yes,left)->saveHand->avg
cond1(no,bottom)->saveHand->avg

```
