# smmrize <!-- omit in toc -->
A CFML wrapper for the [SMMRY API](https://smmry.com/api).  
Utilize the SMMRY API to summarize articles, text, PDFs, etc. by extracting the most important sentences.

*Feel free to use the issue tracker to report bugs or suggest improvements!*

### Acknowledgements <!-- omit in toc -->

This project borrows heavily from the API frameworks built by [jcberquist](https://github.com/jcberquist), such as [xero-cfml](https://github.com/jcberquist/xero-cfml) and [aws-cfml](https://github.com/jcberquist/aws-cfml). Because it draws on those projects, it is also licensed under the terms of the MIT license.

## Table of Contents <!-- omit in toc -->

- [Quick Start](#quick-start)
- [Setup and Usage](#setup-and-usage)
- [Reference Manual](#reference-manual)
- [Reference Manual for `helpers.options`](#reference-manual-for-helpersoptions)

## Quick Start
The following is a minimal example of summarizing a webpage:

```cfc
smmry = new path.to.smmrize.smmry( apiKey = 'xxx' );

summary = smmry.web( 'https://en.wikipedia.org/wiki/Fred_Rogers' );
writeDump( var='#summary#' );
```

## Setup and Usage
To get started with SMMRY, you'll need an API key. You can get this by registering and following the instructions on the [SMMRY website](https://smmry.com/api).

Once you have an API, you can provide it to this wrapper manually, as in the Quick Start example above, or via an environment variable named `SMMRY_API_KEY`.

The API can summarize either web-based content or text, via the `web()` and `text()` methods, respectively. Both these functions take an optional, second argument, which contains the settings for your summarization. The easiest way to provide these is via the `helpers.options` component, which provides a fluent interface for setting them. Here's an example:

```cfc
smmry = new path.to.smmrize.smmry( apiKey = 'xxx' );

options = new path.to.smmrize.helpers.options()
  .sentences( 3 )
  .keywords( 3 )
  .withBreak()
  .withEncode()
  .avoidQuestions();

webpage = 'https://en.wikipedia.org/wiki/Eiffel_Tower';

summary = smmry.web( webpage, options );
writeDump( var='#summary#' );
```

If you prefer, options can be provided manually, as a struct, using the parameters outlined in the [SMMRY documentation](https://smmry.com/api)- the options defined in the previous example, using this approach, would be structured like this:

```cfc
options = {
  'SM_LENGTH': 3,
  'SM_KEYWORD_COUNT': 3,
  'SM_WITH_BREAK': true,
  'SM_WITH_ENCODE': true,
  `SM_QUESTION_AVOID`: true
};
```

## Reference Manual

#### `web( required string url, any options )`
Summarize the content of a webpage. The `options` argument must be either an instance of the `helpers.options` component or a struct defining the summarization options.

#### `text( required string input, any options )`
Summarize a body of text. The `options` argument must be either an instance of the `helpers.options` component or a struct defining the summarization options.

---

## Reference Manual for `helpers.options`
This section documents every public method in the `helpers/options.cfc` file. All of these methods are chainable, enabling you to fluently build your summarization options.

#### `length( required numeric length )`
Sets the number of sentences returned (default 7)

#### `sentences( required numeric length )`
Included to provide a more fluent interface; delegates to `length()`

#### `keywordCount( required numeric count )`
Sets the the number of keywords to return

#### `keywords( required numeric count )`
Included to provide a more fluent interface; delegates to `keywordCount()`

#### `withBreak()`
Inserts the string [BREAK] between sentences.

#### `withEncode()`
Converts HTML entities to their applicable chars.

#### `ignoreLength()`
Returns summary regardless of quality or length.

#### `avoidQuotes()`
Excludes sentences with quotations.

#### `avoidQuestions()`
Excludes sentences that are questions.

#### `avoidExclamations()`
Excludes sentences with exclamation marks.

#### `build()`
The function that puts it all together and builds the `options` struct for use in the API operations.
