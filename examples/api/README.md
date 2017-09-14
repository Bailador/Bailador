Simple API example.  

Since we want to render a JSON response, we can define the default content type of our application to `application/json`.
```perl6
app.config.default-content-type = 'application/json';
```
Finally, we render our data thanks to the `to-json` method, provided by the JSON::Fast module. Bailador automatically calls this method for us.
