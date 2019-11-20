(*
  UTF8ize Plugin

  Copyright (c) 2015 Lyna

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
  claim that you wrote the original software. If you use this software
  in a product, an acknowledgment in the product documentation would be
  appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must not be
  misrepresented as being the original software.

  3. This notice may not be removed or altered from any source
  distribution.
*)
unit UUtf8ize;

interface

procedure Register;

implementation

{$DEFINE APPLYTOALL}
{$IF RTLVersion >= 23.00}
{$DEFINE USENAMESPACE} // XE2 or later
{$IFEND}

uses
{$IFDEF USENAMESPACE}
  Winapi.Windows, System.SysUtils, System.Classes, System.TypInfo, System.Rtti,
{$ELSE}
  Windows, SysUtils, Classes, TypInfo, Rtti,
{$ENDIF}
  ToolsAPI, Events;

// http://docwiki.embarcadero.com/RADStudio/Rio/en/Compiler_Versions
const
  sCoreideName = {$IFDEF VER210}'coreide140.bpl'; {$ENDIF} // 2010
{$IFDEF VER220}'coreide150.bpl'; {$ENDIF} // XE
{$IFDEF VER230}'coreide160.bpl'; {$ENDIF} // XE2
{$IFDEF VER240}'coreide170.bpl'; {$ENDIF} // XE3
{$IFDEF VER250}'coreide180.bpl'; {$ENDIF} // XE4
{$IFDEF VER260}'coreide190.bpl'; {$ENDIF} // XE5
{$IFDEF VER270}'coreide200.bpl'; {$ENDIF} // XE6
{$IFDEF VER280}'coreide210.bpl'; {$ENDIF} // XE7
{$IFDEF VER290}'coreide220.bpl'; {$ENDIF} // XE8
{$IFDEF VER300}'coreide230.bpl'; {$ENDIF} // XE10 Seattle
{$IFDEF VER310}'coreide240.bpl'; {$ENDIF} // XE10.1 Berlin
{$IFDEF VER320}'coreide250.bpl'; {$ENDIF} // XE10.2 Tokyo
{$IFDEF VER330}'coreide260.bpl'; {$ENDIF} // XE10.3 Tokyo
sEvEditBufferCreated = '@Editorbuffer@EvEditBufferCreated';

var
  FEvEditBufferCreated: ^TEvent;
  FUtf8Filter: IOTAFileFilter;

procedure EditBufferCreated(Self, Sender: TObject);
var
  ctx: TRttiContext;
  typ: TRttiType;
{$IFNDEF APPLYTOALL}
  field: TRttiField;
{$ENDIF}
  prop: TRttiProperty;
  vfs: TObject;
begin
  typ := ctx.GetType(Sender.ClassType);

{$IFNDEF APPLYTOALL}
  field := typ.GetField('FileName');
  if field = nil then
    Exit;
  if FileExists(field.GetValue(Sender).AsString) then
    Exit;
{$ENDIF}
  prop := typ.GetProperty('FileSystem');
  if prop = nil then
    Exit;

  vfs := prop.GetValue(Sender).AsObject;
  if vfs = nil then
    Exit;

  typ := ctx.GetType(vfs.ClassType);
  if typ = nil then
    Exit;

  prop := typ.GetProperty('Filter');
  if prop = nil then
    Exit;

  SetInterfaceProp(vfs, TRttiInstanceProperty(prop).PropInfo, FUtf8Filter);
end;

const
  EditBufferCreatedMethod: TMethod = (Code: @EditBufferCreated; Data: nil);

procedure Register;
var
  filtersrv: IOTAFileFilterServices;
  i: Integer;
begin
  filtersrv := BorlandIDEServices as IOTAFileFilterServices;
  FUtf8Filter := nil;
  for i := 0 to filtersrv.FileFilterCount - 1 do
    if SameText(filtersrv.FileFilter[i].IDString,
      'Borland.FileFilter.UTF8ToUTF8') then
    begin
      FUtf8Filter := filtersrv.FileFilter[i];
      Break;
    end;
  if FUtf8Filter = nil then
    Exit;

  FEvEditBufferCreated := GetProcAddress(GetModuleHandle(sCoreideName),
    sEvEditBufferCreated);
  if FEvEditBufferCreated = nil then
    Exit;
  FEvEditBufferCreated^.Add(TNotifyEvent(EditBufferCreatedMethod));
end;

procedure Unregister;
begin
  FUtf8Filter := nil;
  if FEvEditBufferCreated = nil then
    Exit;
  FEvEditBufferCreated^.Remove(TNotifyEvent(EditBufferCreatedMethod));
end;

initialization

finalization

Unregister;

end.
