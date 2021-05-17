# Database

**In memory database**

## Installation

If you using mac, install the latest version of elixir 
`brew install elixir` OR `sudo port install elixir`

FOR windows or linux - https://elixir-lang.org/install.html

Pull the latest version `git clone https://github.com/brangi/in-memory-db`


## Compile

cd `in-memory-db`

run `mix escript.build`

## Run

In the root directory, you should see these files, run `database`

```
README.md	_build		database	lib		mix.exs		test
```


start the program

`./database`

You should be able to input commands 

````
% ./database
>>GET a
NULL
>>SET a foo
>>SET b foo
>>COUNT foo
2
>>COUNT bar
0
>>DELETE a
>>COUNT foo
1
>>SET b baz
>>COUNT foo
0
>>GET b
baz
>>GET B
NULL
>>END
Exit.
````