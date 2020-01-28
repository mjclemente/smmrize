/**
* smmrize
* Copyright 2019-2020  Matthew J. Clemente, John Berquist
* Licensed under MIT (https://github.com/mjclemente/smmrize/blob/master/LICENSE)
*/
component displayname="smmrize"  {

  variables._smmrize_version = '1.0.3';

  public any function init(
    string apiKey = '',
    string baseUrl = "https://api.smmry.com",
    boolean includeRaw = false,
    numeric httpTimeout = 50 ) {

    structAppend( variables, arguments );

    //map sensitive args to env variables or java system props
    var secrets = {
      'apiKey': 'SMMRY_API_KEY'
    };
    var system = createObject( 'java', 'java.lang.System' );

    for ( var key in secrets ) {
      //arguments are top priority
      if ( variables[ key ].len() ) continue;

      //check environment variables
      var envValue = system.getenv( secrets[ key ] );
      if ( !isNull( envValue ) && envValue.len() ) {
        variables[ key ] = envValue;
        continue;
      }

      //check java system properties
      var propValue = system.getProperty( secrets[ key ] );
      if ( !isNull( propValue ) && propValue.len() ) {
        variables[ key ] = propValue;
      }
    }

    //declare file fields to be handled via multipart/form-data **Important** this is not applicable if payload is application/json
    variables.fileFields = [];

    return this;
  }

  /**
  * @hint Summarize the content of a webpage.
  * @options must be either an instance of the `helpers.options` component or a struct defining the summarization options.
  */
  public struct function web( required string url, any options = {} ) {

    var params = {};
    if ( isValid( 'component', options ) )
      params = options.build();
    else if( isStruct( options ) )
      params = options;
    else
      throw( "Invalid argument type. The `options` parameter must be either an instance of the `helpers.options` component or a struct." );

    params[ 'SM_URL' ] = arguments.url;

    return apiCall( 'POST', '/', params );
  }

  /**
  * @hint Summarize a body of text.
  * @options must be either an instance of the `helpers.options` component or a struct defining the summarization options.
  */
  public struct function text( required string input, any options = {} ) {
    var payload = {
      'sm_api_input': input
    };

    var params = {};
    if ( isValid( 'component', options ) )
      params = options.build();
    else if( isStruct( options ) )
      params = options;
    else
      throw( "Invalid argument type. The `options` parameter must be either an instance of the `helpers.options` component or a struct." );

    return apiCall( 'POST', '/', params, payload );
  }

  // PRIVATE FUNCTIONS
  private struct function apiCall(
    required string httpMethod,
    required string path,
    struct queryParams = { },
    any payload = '',
    struct headers = { } )  {

    var fullApiPath = variables.baseUrl & path;
    var requestHeaders = getBaseHttpHeaders();
    requestHeaders.append( headers, true );

    //required for all requests
    queryParams[ 'SM_API_KEY' ] = variables.apiKey;

    var requestStart = getTickCount();
    var apiResponse = makeHttpRequest( httpMethod = httpMethod, path = fullApiPath, queryParams = queryParams, headers = requestHeaders, payload = payload );

    var result = {
      'responseTime' = getTickCount() - requestStart,
      'statusCode' = listFirst( apiResponse.statuscode, " " ),
      'statusText' = listRest( apiResponse.statuscode, " " ),
      'headers' = apiResponse.responseheader
    };

    var parsedFileContent = {};

    // Handle response based on mimetype
    var mimeType = apiResponse.mimetype ?: requestHeaders[ 'Content-Type' ];

    if ( mimeType == 'application/json' && isJson( apiResponse.fileContent ) ) {
      parsedFileContent = deserializeJSON( apiResponse.fileContent );
    } else if ( mimeType.listLast( '/' ) == 'xml' && isXml( apiResponse.fileContent ) ) {
      parsedFileContent = xmlToStruct( apiResponse.fileContent );
    } else {
      parsedFileContent = apiResponse.fileContent;
    }

    //can be customized by API integration for how errors are returned
    //if ( result.statusCode >= 400 ) {}

    //stored in data, because some responses are arrays and others are structs
    result[ 'data' ] = parsedFileContent;

    if ( variables.includeRaw ) {
      result[ 'raw' ] = {
        'method' : ucase( httpMethod ),
        'path' : fullApiPath,
        'params' : parseQueryParams( queryParams ),
        'payload' : parseBody( payload ),
        'response' : apiResponse.fileContent
      };
    }

    return result;
  }

  private struct function getBaseHttpHeaders() {
    return {
      'Accept' : 'application/json',
      'Content-Type' : 'application/x-www-form-urlencoded',
      'User-Agent' : 'smmrize/#variables._smmrize_version# (ColdFusion)'
    };
  }

  private any function makeHttpRequest(
    required string httpMethod,
    required string path,
    struct queryParams = { },
    struct headers = { },
    any payload = ''
  ) {
    var result = '';

    var fullPath = path & ( !queryParams.isEmpty()
      ? ( '?' & parseQueryParams( queryParams, false ) )
      : '' );

    cfhttp( url = fullPath, method = httpMethod,  result = 'result', timeout = variables.httpTimeout ) {

      if ( isJsonPayload( headers ) ) {

        var requestPayload = parseBody( payload );
        if ( isJSON( requestPayload ) )
          cfhttpparam( type = "body", value = requestPayload );

      } else if ( isFormPayload( headers ) ) {

        headers.delete( 'Content-Type' ); //Content Type added automatically by cfhttppparam

        for ( var param in payload ) {
          if ( !variables.fileFields.contains( param ) )
            cfhttpparam( type = 'formfield', name = param, value = payload[ param ] );
          else
            cfhttpparam( type = 'file', name = param, file = payload[ param ] );
        }

      }

      //handled last, to account for possible Content-Type header correction for forms
      var requestHeaders = parseHeaders( headers );
      for ( var header in requestHeaders ) {
        cfhttpparam( type = "header", name = header.name, value = header.value );
      }

    }
    return result;
  }

  /**
  * @hint convert the headers from a struct to an array
  */
  private array function parseHeaders( required struct headers ) {
    var sortedKeyArray = headers.keyArray();
    sortedKeyArray.sort( 'textnocase' );
    var processedHeaders = sortedKeyArray.map(
      function( key ) {
        return { name: key, value: trim( headers[ key ] ) };
      }
    );
    return processedHeaders;
  }

  /**
  * @hint converts the queryparam struct to a string, with optional encoding and the possibility for empty values being pass through as well
  */
  private string function parseQueryParams( required struct queryParams, boolean encodeQueryParams = true, boolean includeEmptyValues = true ) {
    var sortedKeyArray = queryParams.keyArray();
    //lets make sure the API key is first and the url is last
    sortedKeyArray.sort(
      function (e1, e2) {
        if( e1 == 'SM_API_KEY' || e2 == 'SM_URL' )
          return -1;
        else if( e1 == 'SM_URL' || e2 == 'SM_API_KEY' )
          return 1;
        else
          return 0;
      }
    );

    var queryString = sortedKeyArray.reduce(
      function( queryString, queryParamKey ) {
        var encodedKey = encodeQueryParams
          ? encodeUrl( queryParamKey )
          : queryParamKey;
        if ( !isArray( queryParams[ queryParamKey ] ) ) {
          var encodedValue = encodeQueryParams && len( queryParams[ queryParamKey ] )
            ? encodeUrl( queryParams[ queryParamKey ] )
            : queryParams[ queryParamKey ];
        } else {
          var encodedValue = encodeQueryParams && ArrayLen( queryParams[ queryParamKey ] )
            ?  encodeUrl( serializeJSON( queryParams[ queryParamKey ] ) )
            : queryParams[ queryParamKey ].toList();
          }
        return queryString.listAppend( encodedKey & ( includeEmptyValues || len( encodedValue ) ? ( '=' & encodedValue ) : '' ), '&' );
      }, ''
    );

    return queryString.len() ? queryString : '';
  }

  private string function parseBody( required any body ) {
    if ( isStruct( body ) || isArray( body ) )
      return serializeJson( body );
    else if ( isJson( body ) )
      return body;
    else
      return '';
  }

  private string function encodeUrl( required string str, boolean encodeSlash = true ) {
    var result = replacelist( urlEncodedFormat( str, 'utf-8' ), '%2D,%2E,%5F,%7E', '-,.,_,~' );
    if ( !encodeSlash ) result = replace( result, '%2F', '/', 'all' );

    return result;
  }

  /**
  * @hint helper to determine if body should be sent as JSON
  */
  private boolean function isJsonPayload( required struct headers ) {
    return headers[ 'Content-Type' ] == 'application/json';
  }

  /**
  * @hint helper to determine if body should be sent as form params
  */
  private boolean function isFormPayload( required struct headers ) {
    return arrayContains( [ 'application/x-www-form-urlencoded', 'multipart/form-data' ], headers[ 'Content-Type' ] );
  }

  /**
  *
  * Based on an (old) blog post and UDF from Raymond Camden
  * https://www.raymondcamden.com/2012/01/04/Converting-XML-to-JSON-My-exploration-into-madness/
  *
  */
  private struct function xmlToStruct( required any x ) {

    if ( isSimpleValue( x ) && isXml( x ) )
      x = xmlParse( x );

    var s = {};

    if ( xmlGetNodeType( x ) == "DOCUMENT_NODE" ) {
      s[ structKeyList( x ) ] = xmlToStruct( x[ structKeyList( x ) ] );
    }

    if ( structKeyExists( x, "xmlAttributes" ) && !structIsEmpty( x.xmlAttributes ) ) {
      s.attributes = {};
      for ( var item in x.xmlAttributes ) {
        s.attributes[ item ] = x.xmlAttributes[ item ];
      }
    }

    if ( structKeyExists( x, 'xmlText' ) && x.xmlText.trim().len() )
      s.value = x.xmlText;

    if ( structKeyExists( x, "xmlChildren" ) ) {

      for ( var xmlChild in x.xmlChildren ) {
        if ( structKeyExists( s, xmlChild.xmlname ) ) {

          if ( !isArray( s[ xmlChild.xmlname ] ) ) {
            var temp = s[ xmlChild.xmlname ];
            s[ xmlChild.xmlname ] = [ temp ];
          }

          arrayAppend( s[ xmlChild.xmlname ], xmlToStruct( xmlChild ) );

        } else {

          if ( structKeyExists( xmlChild, "xmlChildren" ) && arrayLen( xmlChild.xmlChildren ) ) {
              s[ xmlChild.xmlName ] = xmlToStruct( xmlChild );
           } else if ( structKeyExists( xmlChild, "xmlAttributes" ) && !structIsEmpty( xmlChild.xmlAttributes ) ) {
            s[ xmlChild.xmlName ] = xmlToStruct( xmlChild );
          } else {
            s[ xmlChild.xmlName ] = xmlChild.xmlText;
          }

        }

      }
    }

    return s;
  }

}