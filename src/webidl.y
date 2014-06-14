%lex

integer         "-"?([1-9][0-9]*|"0"[Xx][0-9A-Fa-f]+|"0"[0-7]*)
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
'='             {return '='}
'?'             {return '?'}
'-'             {return '-'}
'...'           {return '...'}
'attribute'     {return 'attribute'}
'boolean'       {return 'boolean'}
'byte'          {return 'byte'}
'callback'      {return 'callback'}
'const'         {return 'const'}
'dictionary'    {return 'dictionary'}
'double'        {return 'double'}
'DOMString'     {return 'DOMString'}
'exception'     {return 'exception'}
'getter'        {return 'getter'}
'false'         {return 'false'}
'float'         {return 'float'}
'implements'    {return 'implements'}
'inherit'       {return 'inherit'}
'Infinity'      {return 'Infinity'}
'interface'     {return 'interface'}
'long'          {return 'long'}
'NaN'           {return 'NaN'}
'null'          {return 'null'}
'object'        {return 'object'}
'octet'         {return 'octet'}
'optional'      {return 'optional'}
'or'            {return 'or'}
'readonly'      {return 'readonly'}
'short'         {return 'short'}
'stringifier'   {return 'stringifier'}
'true'          {return 'true'}
'typedef'       {return 'typedef'}
'void'          {return 'void'}
'unrestricted'  {return 'unrestricted'}
'unsigned'      {return 'unsigned'}
{identifier}    {return 'identifier'}
{float}         {return 'float'}
{integer}       {return 'integer'}
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
        {$$ = $2; $$.callback = true}
    | Interface;

CallbackRestOrInterface
    : CallbackRest
    | Interface;

Interface
    : "interface" identifier Inheritance "{" InterfaceMembers "}" ";"
        {$$ = {definition: $1, name: $2, inherits: $3, members: $5, callback: false};};

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
        {$$ = $3; $$.unshift($2); $2.attributes = $1;}
    |
        {$$ = []};

InterfaceMember
    : Const
    | AttributeOrOperationOrIterator;

Dictionary
    : "dictionary" identifier Inheritance "{" DictionaryMembers "}" ";"
        {$$ = {definition: "dictionary", name: $2, inherits: $3, members: $5}};

DictionaryMembers
    : ExtendedAttributeList DictionaryMember DictionaryMembers
    | DictionaryMember DictionaryMembers
        {$$ = $2; $$.unshift($1)}
    |
        {$$ = []};

DictionaryMember
    : Type identifier Default ";"
        {$$ = {type: $1, name: $2, value: $3, memberType: "dictionaryMember"}};

PartialDictionary
    : "dictionary" identifier "{" DictionaryMembers "}" ";";

Default
    : "=" DefaultValue
    |
        {$$ = null};

DefaultValue
    : ConstValue
    | string;

Exception
    : "exception" identifier Inheritance "{" ExceptionMembers "}" ";"
        {$$ = {definition: $1, name: $2, inherits: $3, members: $5};};

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
    : "typedef" Type identifier ";"
        {$$ = {definition: $1, type: $2, name: $3}};

ImplementsStatement
    : identifier "implements" identifier ";"
        {$$ = {definition: $2, name: $1, implements: $3}};

Const
    : "const" ConstType identifier "=" ConstValue ";"
        {$$ = {memberType: $1, type: $2, name: $3, value: $5}};

ConstValue
    : BooleanLiteral
    | FloatLiteral
    | integer
        {$$ = parseInt($1);}
    | "null"
        {$$ = null};

BooleanLiteral
    : "true"
        {$$ = true}
    | "false"
        {$$ = false};

FloatLiteral
    : float
        {$$ = parseFloat($1)}
    | "-" "Infinity"
        {$$ = -Infinity}
    | "Infinity"
        {$$ = Infinity}
    | "NaN"
        {$$ = NaN};

AttributeOrOperationOrIterator
    : Serializer
    | Stringifier
    | StaticMember
    | Attribute
    | OperationOrIterator;

Serializer
    : "serializer" SerializerRest;

SerializerRest
    : OperationRest
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
    : "stringifier" StringifierRest
        {$$ = $2; $$.stringifier = true;};

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
        {$$ = $1;};

AttributeRest
    : ReadOnly "attribute" Type identifier ";"
        {$$ = {readOnly: $1, memberType: $2, type: $3, name: $4, stringifier: false, inherit: false}}
    | "attribute" Type identifier ";"
        {$$ = {readOnly: false, memberType: $1, type: $2, name: $3, stringifier: false, inherit: false}};

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
    : Special Specials ReturnType OperationRest
        {$$ = $4; $$.specials = $2; $$.specials.unshift($1); $$.returnType = $3;};

Specials
    : Special Specials
        {$$ = $2; $$.unshift($1)}
    |
        {$$ = []};

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
        {$$ = {memberType: 'operation', name: $1, arguments: $3, specials: [], stringifier: false}};

OptionalIdentifier
    : identifier
    |
        {$$ = null};

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
        {$$ = $2; $$.attributes = $1}
    | OptionalOrRequiredArgument;

OptionalOrRequiredArgument
    : "optional" Type ArgumentName Default
        {$$ = {type: $2, name: $3, ellipsis: false, optional: true, default: $4, attributes: []}}
    | Type Ellipsis ArgumentName
        {$$ = {type: $1, name: $3, optional: false, ellipsis: $2, attributes: []}};

ArgumentName
    : ArgumentNameKeyword
    | identifier;

Ellipsis
    : "..."
        {$$ = true}
    |
        {$$ = false};

ExceptionMember
    : Const
    | ExceptionField;

ExceptionField
    : Type identifier ";"
        {$$ = {memberType: 'field', type: $1, name: $2}};

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
    : "(" ArgumentList ")" ExtendedAttributeRest
        {$$ = $4; $$.arguments = $2;}
    | "[" ExtendedAttributeInner "]" ExtendedAttributeRest
    | "{" ExtendedAttributeInner "}" ExtendedAttributeRest
    | Other ExtendedAttributeRest
        {$$ = $2; $2.name = $1 + $2.name;};

ExtendedAttributeRest
    : ExtendedAttribute
    |
        {$$ = {name: "", arguments: []}};

ExtendedAttributeInner
    : "(" ExtendedAttributeInner ")" ExtendedAttributeInner
    | "[" ExtendedAttributeInner "]" ExtendedAttributeInner
    | "{" ExtendedAttributeInner "}" ExtendedAttributeInner
    | OtherOrComma ExtendedAttributeInner
        {$$ = $2; $$.unshift($1)}
    |
        {$$ = []};

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
    : "(" UnionMemberType "or" UnionMemberType UnionMemberTypes ")"
        {$$ = $5; $$.unshift($4); $$.unshift($2);};

UnionMemberType
    : NonAnyType
    | UnionType TypeSuffix
    | "any" "[" "]" TypeSuffix;

UnionMemberTypes
    : "or" UnionMemberType UnionMemberTypes
        {$$ = $3; $$.unshift($2);}
    |
        {$$ = []};

NonAnyType
    : PrimitiveType TypeSuffix
        {$$ = $2; $$.name = $1}
    | "ByteString" TypeSuffix
        {$$ = $2; $$.name = $1}
    | "DOMString" TypeSuffix
        {$$ = $2; $$.name = $1}
    | identifier TypeSuffix
        {$$ = $2; $$.name = $1}
    | "sequence" "<" Type ">" Null
        {$$ = $2; $$.name = $1}
    | "object" TypeSuffix
        {$$ = $2; $$.name = $1}
    | "Date" TypeSuffix
        {$$ = $2; $$.name = $1}
    | "RegExp" TypeSuffix
        {$$ = $2; $$.name = $1};

ConstType
    : PrimitiveType Null
        {$$ = $2; $$.name = $1}
    | identifier Null
        {$$ = $2; $$.name = $1};

PrimitiveType
    : UnsignedIntegerType
    | UnrestrictedFloatType
    | "boolean"
    | "byte"
    | "octet";

UnrestrictedFloatType
    : "unrestricted" FloatType
        {$$ = $1 + " " + $2}
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
        {$$ = $3; $$.array = true}
    | "?" TypeSuffixStartingWithArray
        {$$ = $2; $$.nullable = true}
    |
        {$$ = {array: false, nullable: false}};

TypeSuffixStartingWithArray
    : "[" "]" TypeSuffix
        {$$ = $3; $$.array = true;}
    |
        {$$ = {array: false, nullable: false}};

Null
    : "?"
        {$$ = {array: false, nullable: true}}
    |
        {$$ = {array: false, nullable: false}};

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
