must have / after host

no url params

no query params

only http or https

only json for body

https://discord.com/channels/605571803288698900/1063283835481116754


The auto-generated docs aren't really usable at the minute, it's generally best to read the std source - I promise it's not as scary as it sounds! (If you have literally no idea what you're looking for, grepping through a relevant file for pub fn can often be surprisingly helpful to figure out an API)

In terms of parsing, there are two ways we can do this: streaming and non-streaming input. In most cases, non-streaming is gonna be a little bit faster and the memory usage won't be any big deal, so it's probably the better choice (the main exception would probably be really huge JSON blobs - if you want to look into it, look at StreamingParser in std/json.zig). To use the basic non-streaming parser, you want to construct a std.json.Parser and run parse on it with your input. That'll look like this:
var p = std.json.Parser.init(allo, false);
// ^^ the second arg indicates whether to dupe strings - if we're parsing
// an http request to handle it, the buffer should persist as long as we
// need, so no need to dupe the strings
defer p.deinit();

var vt = try p.parse(req.data);
defer vt.deinit(); // frees associated memory

const root = vt.root;
// now we can pattern match etc on 'root' - see std.json.Value for its structure.
// example to get root.something as an int:
if (root != .Object) return error.BadStructure;
const something = root.Object.get("something") orelse return error.BadStructure;
if (something != .Integer) return error.BadStructure;
const val = something.Integer;
 
Now, obviously, getting the data out of this with correct error handling is pretty cumbersome. If you know the format of the data you're expecting, it might be a good idea to instead use std.json.parse. With this API, you define a struct representing the data you're expecting, and the parser automatically fills that structure:
const Data = struct {
    something: u64,
    array_of_str: []const []const u8,
};

// arena so we can free the whole structure at once rather than traversing it all
var arena = std.heap.ArenaAllocator.init(allo);
defer arena.deinit();

var ts = std.json.TokenStream.init(req.data);
// ^^ this actually uses the streaming parser under the hood, so maybe
// very slightly slower than the Value parsing above, but no biggie
const data = try std.json.parse(Data, &ts, .{ .allocator = arena.allocator() });

// do stuff with data!
 
Stringification is simple: you can just do try std.json.stringify(data, .{}, my_writer), where data is either a std.json.Value or a general struct and it'll be stringified and written to my_writer

jonericcook
OP
 — Today at 7:11 PM
this is gold! thank you!
now i have a ringer question - is there a way to do this parsing but without allocation? I working on a json-rpc "like" http server and client that has zero dynamic memory allocation (trying to be cool like tigerbeetle)
mlugg — Today at 7:19 PM
Since it's a streaming parser, std.json.parse doesn't actually need to allocate for fixed structures! If you just don't set allocator in its options struct (leaving it at its default of null), as long as the type being parsed doesn't require allocation (i.e. no slices), it'll just work 

jonericcook
OP
 — Today at 7:19 PM
and on this journey ive made decisions that make things stricter - like no url params, no query params, only POST methods and only json bodies
so no slices means if we want to work with "strings" it has to be a defined u8 array? like [100]u8

mlugg — Today at 7:25 PM
Hm, I assumed there was a way to make that slice into the original buffer as with the non-streaming parser, but it looks like yeah you'll have to use fixed arrays in the struct instead. That's not ideal, I might have a look at PR'ing some small API cleanups here at some point

&ali — Today at 7:26 PM
you can even parse json at comptime
(see zig website main page)

mlugg — Today at 7:26 PM
Of course, another option is to use something like a FixedBufferAllocator with a small stack buffer (or, if requests are handled strictly sequentially, a decent-size global buffer!) to put the strings in 
But yeah, any of these solutions do put a limit on your maximum string size, which isn't ideal
That's just an unfortunate API limitation at the minute

jonericcook
OP
 — Today at 7:36 PM
i like the idea of working with a check of stack memory - im a bit new to lower level programming but the simple idea was when the program starts its give a huge chunk of stack memory to work with for each request (i doubt id get to multithreading)
i have seen other peoples http servers and saw how they have this chuck of memory they allocate to read in the http request line by line
i thought i could have use a big chuck of memory that is given to me when the program starts up (via comptime?)
i dont know if anything im saying makes sense ha

random internet person — Today at 7:48 PM
this is more an artifact of the fact that you have to give a buffer to the system to read into, and that http headers have a reasonable maximum size, where most webservers will just refuse any requests with more than say, 16 KB of headers. The payload may not be subject to those same bounds

jonericcook
OP
 — Today at 7:53 PM
the final goal for my project is to let the user of it set the bounds for the whole request or for individual parts like the start line, headers and body
i also wonder if you choose to set the limit of a request to be the max stack size the server can ask for from the OS


does fixed buffer allocator help
either do that or i also noticed stringify takes a writer so i imagine you could pass an arraylist writer
no actually array list would not error if it wrote more than you  had allocated
use a fixed buffer allocator
var buffer: [1024]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
// or
const buffer = try allocator.alloc(u8, 1024);
defer allocator.free(buffer);
var fba = std.heap.FixedBufferAllocator.init(buffer);

const res = try std.json.stringifyAlloc(fba.allocator(), .{ .there = @as(u8, 10) }, .{});