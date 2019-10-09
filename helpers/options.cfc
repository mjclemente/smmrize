/**
* smmry.cfc
* Copyright 2019 Matthew Clemente, John Berquist
* Licensed under MIT (https://mit-license.org)
*/
component accessors="true" {

  property name="SM_LENGTH" default="";
  property name="SM_KEYWORD_COUNT" default="";
  property name="SM_WITH_BREAK" default="";
  property name="SM_WITH_ENCODE" default="";
  property name="SM_IGNORE_LENGTH" default="";
  property name="SM_QUOTE_AVOID" default="";
  property name="SM_QUESTION_AVOID" default="";
  property name="SM_EXCLAMATION_AVOID" default="";

  /**
  * @hint No parameters can be passed to init this component. They must be built manually. None are required... but it wouldn't make a lot of sense to use this helper without any options
  */
  public any function init() {
    return this;
  }

  /**
  * @hint Sets the number of sentences returned (default 7)
  */
  public any function length( required numeric length ) {
    setSM_LENGTH( length );
    return this;
  }

  /**
  * @hint Included to provide a more fluent interface; delegates to `length()`
  */
  public any function sentences( required numeric length ) {
    return this.length( length );
  }

  /**
  * @hint Sets the the number of keywords to return
  */
  public any function keywordCount( required numeric count ) {
    setSM_KEYWORD_COUNT( count );
    return this;
  }

  /**
  * @hint Included to provide a more fluent interface; delegates to `keywordCount()`
  */
  public any function keywords( required numeric count ) {
    return keywordCount( count );
  }

  /**
  * @hint Inserts the string [BREAK] between sentences.
  */
  public any function withBreak() {
    setSM_WITH_BREAK( true );
    return this;
  }

  /**
  * @hint Converts HTML entities to their applicable chars.
  */
  public any function withEncode() {
    setSM_WITH_ENCODE( true );
    return this;
  }

  /**
  * @hint Returns summary regardless of quality or length.
  */
  public any function ignoreLength() {
    setSM_IGNORE_LENGTH( true );
    return this;
  }

  /**
  * @hint Excludes sentences with quotations.
  */
  public any function avoidQuotes() {
    setSM_QUOTE_AVOID( true );
    return this;
  }

  /**
  * @hint Excludes sentences that are questions.
  */
  public any function avoidQuestions() {
    setSM_QUESTION_AVOID( true );
    return this;
  }

  /**
  * @hint Excludes sentences with exclamation marks.
  */
  public any function avoidExclamations() {
    setSM_EXCLAMATION_AVOID( true );
    return this;
  }

  /**
  * @hint turns our properties into a struct without the empty values
  */
  public struct function build() {

    var properties = getPropertyValues().reduce(
      function( result, item, index ) {
        result[ "#item.key#" ] = item.value;
        return result;
      }, {}
    );

    return properties
  }


  /**
  * @hint converts the array of properties to an array of their keys/values, while filtering those that have not been set
  */
  private array function getPropertyValues() {

    var propertyValues = getProperties().map(
      function( item, index ) {
        return {
          "key" : item.name,
          "value" : getPropertyValue( item.name )
        };
      }
    );

    return propertyValues.filter(
      function( item, index ) {
        if ( isStruct( item.value ) )
          return !item.value.isEmpty();
        else
          return item.value.len();
      }
    );
  }

  private array function getProperties() {

    var metaData = getMetaData( this );
    var properties = [];

    for( var prop in metaData.properties ) {
      properties.append( prop );
    }

    return properties;
  }

  private any function getPropertyValue( string key ){
    var method = this["get#key#"];
    var value = method();
    return value;
  }
}