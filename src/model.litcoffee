# Model - instance of schema-driven data

The `Model` class is where the [Yang](./yang.litcoffee) schema
expression and the data object come together to provide the *adaptive*
and *event-driven* data interactions.

It is typically not instantiated directly, but is generated as a
result of [Yang::eval](./yang.litcoffee#eval-data-opts).

```javascript
var schema = Yang.parse('container foo { leaf a { type uint8; } }');
var model = schema.eval({ foo: { a: 7 } });
// model is { foo: [Getter/Setter] }
// model.foo is { a: [Getter/Setter] }
// model.foo.a is 7
```
The generated `Model` is a hierarchical composition of
[Property](./property.coffee) instances bound to the `Object` via
`Object.defineProperty`. It acts like a shadow `Proxy/Reflector` to
the `Object` instance and provides tight control via the
`Getter/Setter` interfaces.

# Class Model - Source Code

    Emitter    = require './emitter'
    XPath      = require './xpath'
    Expression = require './expression'

    class Model extends Emitter

      constructor: (schema, props={}) ->
        unless schema instanceof Expression
          throw new Error "cannot create a new Model without schema Expression"

        super
        unless schema.kind is 'module'
          schema = (new Expression 'module').extends schema

        prop.join this for k, prop of props when prop.schema in schema.nodes

        Object.defineProperties this,
          '_id': value: schema.tag ? Object.keys(this).join('+')
          '__':  value: { name: schema.tag, schema: schema }
        Object.preventExtensions this

## Instance-level methods

### on (event)

The `Model` instance is an `EventEmitter` and you can attach various
event listeners to handle events generated by the `Model`:

event | arguments | description
--- | --- | ---
update | (prop, prev) | fired whenever an update takes place within the data tree. 
change |

It also accepts optional XPATH expressions which will *filter* for
granular event subscription to specified events from only the elements
of interest.

The event listeners to the `Model` can handle any customized behavior
such as saving to database, updating read-only state, scheduling
background tasks, etc.

      on: (event, xpath..., callback) ->
        #unless xpath.every (x) -> typeof x is 'string'
        return super event, callback unless xpath.length and callback?
        @on event, (prop, args...) ->
          if prop.path in xpath
            callback.apply this, [prop].concat args

### in (uri)

A helper routine to parse REST URI and discover XPATH and Yang
This facility is still *experimental* and subject to change.

TODO: make URI parsing to be XPATH configurable

      in: (uri='') ->
        keys = uri.split('/').filter (x) -> x? and !!x
        expr = @__.schema
        unless keys.length
          return {
            model:  this
            schema: expr
            path:   XPath.parse '.'
            match:  this
          }
        key = keys.shift()
        expr = switch
          when expr.tag is key then expr
          else expr.locate key
        str = "/#{key}"
        while (key = keys.shift()) and expr?
          if expr.kind is 'list' and not (expr.locate key)?
            str += "[key() = '#{key}']"
            key = keys.shift()
            li = true
            break unless key?
          expr = expr.locate key
          str += "/#{expr.datakey}" if expr?
        return if keys.length or not expr?

        xpath = XPath.parse str
        #temp = xpath
        #key = temp.tag while (temp = temp.xpath)

        match = xpath.apply this
        match = switch
          when not match?.length then undefined
          when /list$/.test(expr.kind) and not li then match
          when match.length > 1 then match
          else match[0]

        return {
          model:  this
          schema: expr
          path:   xpath
          match:  match
          key:    expr.datakey
        }

## Export Model Class

    module.exports = Model