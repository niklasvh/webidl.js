%lex

integer         "-"?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)
float           "-"?(([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+-]?[0-9]+)?|[0-9]+[Ee][+-]?[0-9]+)
identifier      "_"?[A-Za-z][0-9A-Z_a-z]*
string          "[^"]*"
whitespace      [\t\n\r ]+
comment         \/\/.*|\/\*(.|\n)*?\*\/
other           [^\t\n\r 0-9A-Za-z]

%%
\s+             /* skip whitespace */
{whitespace}    /* skip whitespace */
\/\/[^\n]*      /* skip comment */
\#[^\n]*        /* skip comment */
':'             {return ':'}
';'             {return ';'}
','             {return ','}
'{'             {return '{'}
'}'             {return '}'}
'['             {return '['}
']'             {return ']'}
'('             {return '('}
')'             {return ')'}
'attribute'     {return 'attribute'}
'DOMString'     {return 'DOMString'}
'exception'     {return 'exception'}
'float'         {return 'float'}
'inherit'       {return 'inherit'}
'interface'     {return 'interface'}
'long'          {return 'long'}
'readonly'      {return 'readonly'}
'void'          {return 'void'}
'unsigned'      {return 'unsigned'}
{identifier}    {return 'identifier'}
<<EOF>>         {return 'EOF'}
/lex

%%

WebIDL
    : Definitions EOF
        {return $1};

Definitions
    : Definition Definitions
        {
            $$ = $2;
            $1.attributes = [];
            $$.unshift($1);
        }
    | ExtendedAttributeList Definition Definitions
        {
            $$ = $3;
            $2.attributes = $1;
            $$.unshift($2);
        }
    |
        {$$ = []};

Definition
    : CallbackOrInterface
    | Partial
    | Dictionary
    | Exception
    | Enum
    | Typedef
    | ImplementsStatement;

CallbackOrInterface
    : "callback" CallbackRestOrInterface
    | Interface;

CallbackRestOrInterface
    : CallbackRest
    | Interface;

Interface
    : "interface" identifier Inheritance "{" InterfaceMembers "}" ";"
        {$$ = {type: $1, name: $2, inherits: $3, members: $5};};

Partial
    : "partial" PartialDefinition;

PartialDefinition
    : PartialInterface
    | PartialDictionary;

PartialInterface
    : "interface" identifier "{" InterfaceMembers "}" ";";

InterfaceMembers
    : InterfaceMember InterfaceMembers
        {$$ = $2; $$.unshift($1)}
    | ExtendedAttributeList InterfaceMember InterfaceMembers
    |
        {$$ = []};

InterfaceMember
    : Const
    | AttributeOrOperationOrIterator;

Dictionary
    : "dictionary" identifier Inheritance "{" DictionaryMembers "}" ";";

DictionaryMembers
    : ExtendedAttributeList DictionaryMember DictionaryMembers
    | ε;

DictionaryMember
    : Type identifier Default ";";

PartialDictionary
    : "dictionary" identifier "{" DictionaryMembers "}" ";";

Default
    : "=" DefaultValue
    | ε;

DefaultValue
    : ConstValue
    | string;

Exception
    : "exception" identifier Inheritance "{" ExceptionMembers "}" ";"
        {$$ = {type: $1, name: $2, inherits: $3, members: $5};};

ExceptionMembers
    : ExtendedAttributeList ExceptionMember ExceptionMembers
    | ExceptionMember ExceptionMembers
        {$$ = $2; $$.unshift($1)}
    |
        {$$ = []};

Inheritance
    : ":" identifier
        {$$ = $2}
    |
        {$$ = null};

Enum
    : "enum" identifier "{" EnumValueList "}" ";";

EnumValueList
    : string EnumValueListComma;

EnumValueListComma
    : "," EnumValueListString
    | ε;

EnumValueListString
    : string EnumValueListComma
    | ε;

CallbackRest
    : identifier "=" ReturnType "(" ArgumentList ")" ";";

Typedef
    : "typedef" Type identifier ";";

ImplementsStatement
    : identifier "implements" identifier ";";

Const
    : "const" ConstType identifier "=" ConstValue ";";

ConstValue
    : BooleanLiteral
    | FloatLiteral
    | integer
    | "null";

BooleanLiteral
    : "true"
    | "false";

FloatLiteral
    : float
    | "-Infinity"
    | "Infinity"
    | "NaN";

AttributeOrOperationOrIterator
    : Serializer
    | Stringifier
    | StaticMember
    | Attribute
    | OperationOrIterator;

Serializer
    : "serializer" SerializerRest;

SerializerRest : OperationRest
    | "=" SerializationPattern
    | ε;

SerializationPattern
    : "{" SerializationPatternMap "}"
    | "[" SerializationPatternList "]"
    | identifier;

SerializationPatternMap
    : "getter"
    | "inherit" Identifiers
    | identifier Identifiers
    | ε;

SerializationPatternList
    : "getter"
    | identifier Identifiers
    | ε;

Identifiers
    : "," identifier Identifiers
    | ε;

Stringifier
    : "stringifier" StringifierRest;

StringifierRest
    : AttributeRest
    | ReturnType OperationRest
    | ";";

StaticMember
    : "static" StaticMemberRest;

StaticMemberRest
    : AttributeRest
    | ReturnType OperationRest;

Attribute
    : Inherit AttributeRest
        {$$ = $2; $$.inherit = $1}
    | AttributeRest
        {$$ = $1; $$.inherit = false};

AttributeRest
    : ReadOnly "attribute" Type identifier ";"
        {$$ = {readOnly: $1, memberType: $2, type: $3, name: $4}}
    | "attribute" Type identifier ";"
        {$$ = {readOnly: false, memberType: $1, type: $2, name: $3}};

Inherit
    : "inherit"
        {$$ = true}
    |
        {$$ = false};

ReadOnly
    : "readonly"
        {$$ = true}
    |
        {$$ = false};

OperationOrIterator
    : ReturnType OperationOrIteratorRest
        {$$ = $2; $$.returnType = $1}
    | SpecialOperation;

SpecialOperation
    : Special Specials ReturnType OperationRest;

Specials
    : Special Specials
    | ε;

Special
    : "getter"
    | "setter"
    | "creator"
    | "deleter"
    | "legacycaller";

OperationOrIteratorRest
    : IteratorRest
    | OperationRest
        {$$ = $1};

IteratorRest
    : "iterator" OptionalIteratorInterfaceOrObject ";";

OptionalIteratorInterfaceOrObject
    : OptionalIteratorInterface
    | "object";

OptionalIteratorInterface
    : "=" identifier
    | ε;

OperationRest
    : OptionalIdentifier "(" ArgumentList ")" ";"
        {$$ = {memberType: 'operation', name: $1, arguments: $3}};

OptionalIdentifier
    : identifier
    | ε;

ArgumentList
    : Argument Arguments
        {$$ = $2; $2.unshift($1)}
    |
        {$$ = []};

Arguments
    : "," Argument Arguments
        {$$ = $3; $$.unshift($2)}
    |
        {$$ = []};

Argument
    : ExtendedAttributeList OptionalOrRequiredArgument
    | OptionalOrRequiredArgument;

OptionalOrRequiredArgument
    : "optional" Type ArgumentName Default
    | Type Ellipsis ArgumentName
        {$$ = {type: $1, name: $3}};

ArgumentName
    : ArgumentNameKeyword
    | identifier;

Ellipsis
    : "..."
    | ε;

ExceptionMember
    : Const
    | ExceptionField;

ExceptionField
    : Type identifier ";"
        {$$ = {type: $1, name: $2}};

ExtendedAttributeList
    : "[" ExtendedAttribute ExtendedAttributes "]"
        {$$ = $3; $$.push($2);}
    |
        {$$ = []};

ExtendedAttributes
    : ',' ExtendedAttribute ExtendedAttributes
         {$$ = $3; $$.push($2);}
    |
         {$$ = []};

ExtendedAttribute
    : "(" ExtendedAttributeInner ")" ExtendedAttributeRest
    | "[" ExtendedAttributeInner "]" ExtendedAttributeRest
    | "{" ExtendedAttributeInner "}" ExtendedAttributeRest
    | Other ExtendedAttributeRest;

ExtendedAttributeRest
    : ExtendedAttribute
    | ε;

ExtendedAttributeInner
    : "(" ExtendedAttributeInner ")" ExtendedAttributeInner
    | "[" ExtendedAttributeInner "]" ExtendedAttributeInner
    | "{" ExtendedAttributeInner "}" ExtendedAttributeInner
    | OtherOrComma ExtendedAttributeInner
    | ε;

Other
    : integer
    | float
    | identifier
    | string
    | other
    | "-"
    | "-Infinity"
    | "."
    | "..."
    | ":"
    | ";"
    | "<"
    | "="
    | ">"
    | "?"
    | "ByteString"
    | "Date"
    | "DOMString"
    | "Infinity"
    | "NaN"
    | "RegExp"
    | "any"
    | "boolean"
    | "byte"
    | "double"
    | "false"
    | "float"
    | "long"
    | "null"
    | "object"
    | "octet"
    | "or"
    | "optional"
    | "sequence"
    | "short"
    | "true"
    | "unsigned"
    | "void"
    | ArgumentNameKeyword;

ArgumentNameKeyword
    : "attribute"
    | "callback"
    | "const"
    | "creator"
    | "deleter"
    | "dictionary"
    | "enum"
    | "exception"
    | "getter"
    | "implements"
    | "inherit"
    | "interface"
    | "legacycaller"
    | "partial"
    | "serializer"
    | "setter"
    | "static"
    | "stringifier"
    | "typedef"
    | "unrestricted";

OtherOrComma
    : Other
    | ",";

Type
    : SingleType
    | UnionType TypeSuffix;

SingleType
    : NonAnyType
    | "any" TypeSuffixStartingWithArray;

UnionType
    : "(" UnionMemberType "or" UnionMemberType UnionMemberTypes ")";

UnionMemberType
    : NonAnyType
    | UnionType TypeSuffix
    | "any" "[" "]" TypeSuffix;

UnionMemberTypes
    : "or" UnionMemberType UnionMemberTypes
    | ε;

NonAnyType
    : PrimitiveType TypeSuffix
    | "ByteString" TypeSuffix
    | "DOMString" TypeSuffix
    | identifier TypeSuffix
    | "sequence" "<" Type ">" Null
    | "object" TypeSuffix
    | "Date" TypeSuffix
    | "RegExp" TypeSuffix;

ConstType : PrimitiveType Null
    | identifier Null;

PrimitiveType
    : UnsignedIntegerType
    | UnrestrictedFloatType
    | "boolean"
    | "byte"
    | "octet";

UnrestrictedFloatType
    : "unrestricted" FloatType
    | FloatType;

FloatType
    : "float"
    | "double";

UnsignedIntegerType
    : "unsigned" IntegerType
        {$$ = $1 + " " + $2}
    | IntegerType;

IntegerType
    : "short"
    | "long" OptionalLong;

OptionalLong
    : "long"
    | ε;

TypeSuffix
    : "[" "]" TypeSuffix
    | "?" TypeSuffixStartingWithArray
    | ε;

TypeSuffixStartingWithArray
    : "[" "]" TypeSuffix
    | ε;

Null
    : "?"
    | ε;

ReturnType
    : Type
        {$$ = $1}
    | "void"
        {$$ = null};

IdentifierList
    : identifier Identifiers;

Identifiers
    : "," identifier Identifiers
    | ε;

ExtendedAttributeNoArgs
    : identifier;

ExtendedAttributeArgList
    : identifier "(" ArgumentList ")";

ExtendedAttributeIdent
    : identifier "=" identifier;

ExtendedAttributeIdentList
    : identifier "=" IdentifierList;

ExtendedAttributeNamedArgList
    : identifier "=" identifier "(" ArgumentList ")";

ExtendedAttributeTypePair
    : identifier "(" Type "," Type ")";
