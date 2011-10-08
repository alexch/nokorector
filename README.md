# Nokorector

An experimental XML/HTML builder framework.

* definition: "seed" is a nascent XML/HTML node or fragment or doc; think of it as the output stream
* `include Builder` gives your object some methods and a `@_seed` instance variable
* using the macro `tag` defines a method that, when called, will add an XML/HTML element to the seed
* the tag methods work like Erector (or Nokogiri::Builder) methods: they can take text (for inner text content), a hash (for attributes), or a block (for nested content)
* a tag method adds its element to the seed (a growing XML/HTML document), but it also returns a pointer to itself within that seed
* callers can then use that pointer to manipulate the element inside the growing document...
  * by sending it messages, which it uses to define attributes like `class` and `id`
  * by assigning it to a variable, for later use
  * by using it as a parameter to the `put` method
* the `put` method adds its arguments to the seed; if one of those arguments is a seed, then it **moves** the node the seed is pointing to

The upshot of all the above is to enable some slick and (hopefully) fairly well-defined builder DSL tricks, like this:

    put "a", b("c"), "d"
    #=> a<b>c</b>d

    div.foo("bar") do
      baz.src = "baf"
    end
    #=> <div class="foo">bar<baz src="baf"></baz></div>

(Some of these tricks don't quite work yet, but I'm thinking of a data structure tweak to allow them all.)

See `spec/builder_spec.rb` for usage details.

