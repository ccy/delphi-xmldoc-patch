unit Xml.XMLDoc.Patch;

interface

implementation

uses
  System.Rtti, System.SysUtils, XML.XMLConst, Xml.XMLDoc, XML.xmldom, XML.XMLIntf,
  DDetours;

type
  TXMLNodeHelper = class helper for TXMLNode
    class function AddChild_Address: Pointer;
    class function CreateCollection_Address: Pointer;
    class function RegisterChildNode_Address: Pointer;
    function AddChild_Patch(const TagName: DOMString; Index: Integer = -1): IXMLNode;
    function CreateCollection_Patch(const CollectionClass: TXMLNodeCollectionClass;
        const ItemInterface: TGuid; const ItemTag: DOMString; ItemNS: DOMString =
        ''): TXMLNodeCollection;
    procedure RegisterChildNode_Patch(const TagName: DOMString;
      ChildNodeClass: TXMLNodeClass; NamespaceURI: DOMString = '');
  end;

  TXMLNodeListHelper = class helper for TXMLNodeList
    class function FindNode_Address: Pointer;
    function FindNode_Patch(NodeName: DOMString): IXMLNode;
  end;

var TXMLNode_AddChild: function(Self: TXMLNode; const TagName: DOMString; Index: Integer = -1): IXMLNode = nil;

var TXMLNode_CreateCollection: function(Self: TXMLNode;
      const CollectionClass: TXMLNodeCollectionClass; const ItemInterface: TGuid;
      const ItemTag: DOMString; ItemNS: DOMString = ''): TXMLNodeCollection = nil;

var TXMLNode_RegisterChildNode: procedure(Self: TXMLNode; const TagName: DOMString;
      ChildNodeClass: TXMLNodeClass; NamespaceURI: DOMString = '') = nil;

var TXMLNodeList_FindNode: function(Self: TXMLNodeList; NodeName: DOMString): IXMLNode = nil;

function TXMLNodeHelper.AddChild_Patch(const TagName: DOMString;
  Index: Integer): IXMLNode;
begin
  var TagName_Patch := TagName;
  if not IsPrefixed(TagName_Patch) then begin
    for var o in ChildNodeClasses do begin
      if o.NodeName = TagName_Patch then begin
        var Prefix := o.NodeClass.ClassName;
        var i := Prefix.IndexOf('_');
        if i <> -1 then begin
          Prefix := Prefix.Substring(i + 1, MaxInt);
          TagName_Patch := MakeNodeName(Prefix, TagName_Patch);
        end;
        Break;
      end;
    end;
  end;

  Result := TXMLNode_AddChild(Self, TagName_Patch, Index);
end;

class function TXMLNodeHelper.AddChild_Address: Pointer;
var P: function(const TagName: DOMString; Index: Integer = -1): IXMLNode of object;
begin
  P := TXMLNode(nil).AddChild;
  Result := @P;
end;

class function TXMLNodeHelper.CreateCollection_Address: Pointer;
begin
  Result := @TXMLNode.CreateCollection;
end;

function TXMLNodeHelper.CreateCollection_Patch(const CollectionClass:
    TXMLNodeCollectionClass; const ItemInterface: TGuid; const ItemTag:
    DOMString; ItemNS: DOMString = ''): TXMLNodeCollection;
begin
  if ItemNS = '' then begin
    var s := CollectionClass.ClassName;
    var i := s.IndexOf('_');
    if i <> -1 then begin
      var sPrefix := s.Substring(i + 1, MaxInt);
      const NodeListSuffix = 'List';
      if sPrefix.EndsWith(NodeListSuffix) then
        sPrefix := sPrefix.Remove(sPrefix.Length - NodeListSuffix.Length, NodeListSuffix.Length);
      ItemNS := FindNamespaceURI(sPrefix);
    end;
  end;

  Result := TXMLNode_CreateCollection(Self, CollectionClass, ItemInterface, ItemTag, ItemNS);
end;

class function TXMLNodeHelper.RegisterChildNode_Address: Pointer;
begin
  Result := @TXMLNode.RegisterChildNode;
end;

procedure TXMLNodeHelper.RegisterChildNode_Patch(const TagName: DOMString;
  ChildNodeClass: TXMLNodeClass; NamespaceURI: DOMString);
begin
  if NamespaceURI = '' then begin
    var s := ChildNodeClass.ClassName;
    var i := s.IndexOf('_');
    if i <> -1 then begin
      var sPrefix := s.Substring(i + 1, MaxInt);
      NamespaceURI := FindNamespaceURI(sPrefix);
      if NamespaceURI = '' then begin
        var R := TRttiContext.Create.GetType(ClassInfo);
        for var A in R.GetAttributes do begin
          if A is StoredAttribute then begin
            var B := A as StoredAttribute;
            for var t in B.Name.Split([sLineBreak]) do begin
              var M := t.split(['=']);
              if Length(M) = 2 then begin
                var N := M[0].Split([NSDelim]);
                if (Length(N) = 2) and SameText(N[0].Trim, SXMLNS) then
                  DeclareNamespace(N[1].Trim, M[1].Trim.DeQuotedString('"'));
              end;
            end;
          end;
        end;
        NamespaceURI := FindNamespaceURI(sPrefix);
      end;
    end;
  end;

  TXMLNode_RegisterChildNode(Self, TagName, ChildNodeClass, NamespaceURI);
end;

class function TXMLNodeListHelper.FindNode_Address: Pointer;
var P: function(NodeName: DOMString): IXMLNode of object;
begin
  P := TXMLNodeList(nil).FindNode;
  Result := @P;
end;

function TXMLNodeListHelper.FindNode_Patch(NodeName: DOMString): IXMLNode;
begin
  Result := TXMLNodeList_FindNode(Self, NodeName);
  if Result = nil then begin
    for var i := 0 to Count - 1 do begin
      var N := Get(i);
      if (N.LocalName = NodeName) or (N.NodeName = NodeName) then begin
        Result := FindNode(NodeName, N.NamespaceURI);
        Break;
      end;
    end;
  end;
end;

initialization
  TXMLNode_AddChild := InterceptCreate(TXMLNode.AddChild_Address, @TXMLNode.AddChild_Patch);
  TXMLNode_CreateCollection := InterceptCreate(TXMLNode.CreateCollection_Address, @TXMLNode.CreateCollection_Patch);
  TXMLNode_RegisterChildNode := InterceptCreate(TXMLNode.RegisterChildNode_Address, @TXMLNode.RegisterChildNode_Patch);
  TXMLNodeList_FindNode := InterceptCreate(TXMLNodeList.FindNode_Address, @TXMLNodeList.FindNode_Patch);
finalization
  InterceptRemove(@TXMLNode_AddChild);
  InterceptRemove(@TXMLNode_CreateCollection);
  InterceptRemove(@TXMLNode_RegisterChildNode);
  InterceptRemove(@TXMLNodeList_FindNode);
end.
