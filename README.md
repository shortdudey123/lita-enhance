# lita-enhance

Enhances text that contains opaque machine identifiers by replacing them with that machine's hostname.

```
you> enhance 10.214.0.1
lita> *box01*
```

Text that is enhanced is returned in the same format that is passed in, which makes enhancing log lines or CLI output nice to view.

```
you> enhance Finished hinted handoff of 8826 rows to endpoint /192.168.100.1
lita> Finished hinted handoff of 8826 rows to endpoint /*box01*

you> enhance tcp        0      0 10.214.0.1:ssh       10.214.0.2:4997     ESTABLISHED
lita> tcp        0      0 *box01*:ssh             *box02*:4997     ESTABLISHED
```

You can increase the level of enhancement to add more machine details to the output.

```
you> enhance 10.214.0.1
lita> *box01*

you> enhance lvl:2 10.214.0.1
lita> *box01 (us-west-2)*
```

Machine details are obtained by indexing database of machine assets. Right now only Chef servers are indexed. Results are indexed every 15 minutes by default. Old machines are left in the index so you can identify them even after they have been torn down.

```
you> enhance lvl:2 old-box01
lita> ?old-box01 (us-east-1)?
```

[And for fun](https://www.youtube.com/watch?v=Vxq9yj2pVWk), you can implicitly enhance previously enhanced text by just sending ```enhance```. The string to enhance is retained separately in each room that the enhance string was sent.

```
you> enhance 10.214.0.1
lita> *box01*

you> enhance
lita> *box01 (us-west-2)*
```

## Installation

Add lita-enhance to your Lita instance's Gemfile:

``` ruby
gem "lita-enhance"
```

## Configuration

```ruby
# Configure one or more knife files for the Chef server that lita-enhance should index
config.handlers.enhance.knife_configs = {
  'staging' => 'knife-staging.rb',
  'production' => 'knife-production.rb'
}

# How often to refresh enhance's index in seconds. Default is 15 minutes.
config.handlers.enhance.refresh_interval = 15 * 60

# How long in seconds to remember messages to implicitly enhance. Default is 1 week.
config.handlers.enhance.blurry_message_ttl = 7 * 24 * 60 * 60
```

## Usage

```
# Enhance IP addresses (public and private) with the machine's name if it is known
enhance 54.189.200.22
enhance 10.214.0.1

# Enhance EC2 host names
enhance ec2-54-189-200-22.us-west-2.compute.amazonaws.com
enhance ip-10-214-13-102.us-west-2.compute.internal

# Enhance host names (short & long)
enhance box01
enhance box01.example.com

# Enhance EC2 instance IDs
enhance i-123456

# Enhance MAC addresses
enhance 22:00:0a:00:32:23
```

## License

[MIT](http://opensource.org/licenses/MIT)
