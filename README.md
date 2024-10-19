<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://tggl.io/tggl-io-logo-white.svg">
    <img align="center" alt="Tggl Logo" src="https://tggl.io/tggl-io-logo-black.svg" width="200rem" />
  </picture>
</p>

<h1 align="center">Tggl Ruby SDK</h1>

<p align="center">
  The Ruby SDK can be used both on the client and server to evaluate flags and report usage to the Tggl API or a <a href="https://tggl.io/developers/evaluating-flags/tggl-proxy">proxy</a>.
</p>

<p align="center">
  <a href="https://tggl.io/">🔗 Website</a>
  •
  <a href="https://tggl.io/developers/sdks/ruby">📚 Documentation</a>
  •
  <a href="https://rubygems.org/gems/tggl">📦 RubyGem</a>
  •
  <a href="https://www.youtube.com/@Tggl-io">🎥 Videos</a>
</p>

## Usage

Install the dependency:

```bash
gem install tggl
```

Start evaluating flags:

```rb
require "tggl"
 
$client = Tggl::Client.new("YOUR_API_KEY")
 
# An API call to Tggl is performed here
$flags = $client.eval_context({
  userId: "abc",
  email: "foo@gmail.com",
  country: "FR",
  # ...
})
 
if $flags.is_active? "my-feature"
  # ...
end
 
if $flags.get "my-feature" == "Variation A"
  # ...
end
```
