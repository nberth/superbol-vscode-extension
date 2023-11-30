(**************************************************************************)
(*                                                                        *)
(*                        SuperBOL OSS Studio                             *)
(*                                                                        *)
(*  Copyright (c) 2022-2023 OCamlPro SAS                                  *)
(*                                                                        *)
(* All rights reserved.                                                   *)
(* This source code is licensed under the GNU Affero General Public       *)
(* License version 3 found in the LICENSE.md file in the root directory   *)
(* of this source tree.                                                   *)
(*                                                                        *)
(**************************************************************************)

val handle: Jsonrpc.Request.t -> (Lsp_server.state as 's) -> 's * Jsonrpc.Response.t

module INTERNAL: sig
  val lookup_definition
    : Lsp_server.t
    -> Lsp.Types.DefinitionParams.t
    -> [> `Location of Lsp.Types.Location.t list ] option
  val lookup_definition_in_doc
    : Lsp.Types.DefinitionParams.t
    -> Lsp_document.checked_doc
    -> [> `Location of Lsp.Types.Location.t list ] option
  val lookup_references
    : Lsp_server.t
    -> Lsp.Types.ReferenceParams.t
    -> Lsp.Types.Location.t list option
  val lookup_references_in_doc
    : Lsp.Types.ReferenceParams.t
    -> Lsp_document.checked_doc
    -> Lsp.Types.Location.t list option
  val hover
    : Lsp_server.t
    -> Lsp.Types.HoverParams.t
    -> Lsp.Types.Hover.t option
  val formatting
    : Lsp_server.t
    -> Lsp.Types.DocumentFormattingParams.t
    -> Lsp.Types.TextEdit.t list option
end
