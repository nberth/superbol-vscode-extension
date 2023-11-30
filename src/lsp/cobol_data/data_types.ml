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

(** Representation of COBOL data items *)

open Cobol_common.Srcloc.TYPES

module NEL = Cobol_common.Basics.NEL
type 'a nel = 'a NEL.t

type picture_config = Data_picture.TYPES.config
type picture = Data_picture.t

type usage =
  | Usage of picture                                               (* for now *)

type data_storage =
  | File
  | Local_storage
  | Working_storage
  | Linkage                                                          (* file? *)

let pp_data_storage ppf s =
  Fmt.string ppf @@ match s with
  | File -> "FILE"
  | Local_storage -> "LOCAL-STORAGE"
  | Working_storage -> "WORKING-STORAGE"
  | Linkage -> "LINKAGE"

type (* 'length *) length =
  | Fixed_length(* : [>`fixed_length] length *)
  | Variable_length(* : [>`variable_length] length *)

(* type item_offset = *)
(*   (\* To be completed *\) *)
(*   | Offset of Cobol_ptree.qualname *)

type record =
  {
    record_name: string;
    record_storage: data_storage;
    record_item: item_definition with_loc;
    record_renamings: record_renamings;
  }
and item_definitions = item_definition with_loc nel
and item_redefinitions = item_definition with_loc list
and item_definition =
  {
    (* Note: location of qualname corresponds to the *unqualified* name, with
       implicit qualification based on item groups. *)
    item_qualname: Cobol_ptree.qualname with_loc option;
    item_redefines: Cobol_ptree.qualname with_loc option;       (* redef only *)
    item_layout: item_layout;
    item_offset: Data_memory.offset;          (** offset w.r.t record address *)
    item_size: Data_memory.size;
    item_length: length;
    item_redefinitions: item_redefinitions;
  }
and item_layout =
  | Elementary_item of
      {
        usage: usage;
        value: Cobol_ptree.literal with_loc option;
      }
  | Struct_item of
      {
        fields: item_definitions;
      }
  (* | FlexibleStruct: *)
  (*     { *)
  (*       (\* only last may be of variable length, unless ODOSLIDE is on *\) *)
  (*       fields: ([>`fixed_length *)
  (*                | `variable_length                 (\* <- to allow ODOSLIDE *\) *)
  (*                ] item_definitions, 'a item_definitions) nel'; *)
  (*     } *)
  (*     -> ([>`simple], [>`fixed_length | `variable_length] as 'a) item_layout *)
  | Fixed_table of                                          (* OCCURS _ TIMES *)
      {
        items: item_definitions;
        length: int with_loc;                                  (* int for now *)
        value: Cobol_ptree.literal with_loc option;
        (* TODO: keys, indexing; *)
      }
  (* -> ([>`table], [>`fixed_length]) item_layout *)
  | Depending_table of                  (* OCCURS _ TO _ TIMES DEPENDING ON _ *)
      {
        (* no subordinate OCCURS DEPENDING: *)
        items: item_definitions;
        min_occurs: int with_loc;                              (* int for now *)
        max_occurs: int with_loc;                              (* ditto *)
        depending: Cobol_ptree.qualname with_loc;
        value: Cobol_ptree.literal with_loc option;
        (* TODO: keys, indexing; *)
      }
  (* -> ([>`table], [>`variable_length]) item_layout *)
  | Dynamic_table of                 (* OCCURS DYNAMIC CAPACITY _ FROM _ TO _ *)
      {
        items: item_definitions;
        capacity: Cobol_ptree.qualname with_loc option;
        min_capacity: int with_loc option;
        max_capacity: int with_loc option;
        value: Cobol_ptree.literal with_loc option;
        initialized: bool with_loc;
        (* TODO: keys, indexing *)
      } (* NOTE: considered fixed-length in ISO/IEC *)
(* -> ([>`table], [>`fixed_length]) item_layout *)

(** Note: RENAMES could be represented by simply adding an (optional,
    non-constant) offset to redefinitions (and use group layouts with FILLERs
    throughout to forbid using the new name as a qualifier).

    Such a representation would be much more general than what typical COBOL
    data definitions allow; in particular, one could have "shifted" redefintions
    of any non-01 group item.

    However, we keep the distinction between RENAMES and REDEFINES to better
    match said typical COBOL, and possibly allow more detailed error
    reporting. *)
and record_renamings = record_renaming with_loc list
and record_renaming =
  {
    renaming_name: Cobol_ptree.qualname with_loc;
    renaming_layout: renamed_item_layout;
    renaming_offset: Data_memory.offset;
    renaming_size: Data_memory.size;
    renaming_from: Cobol_ptree.qualname with_loc;
    renaming_thru: Cobol_ptree.qualname with_loc option;
  }
and renamed_item_layout =
  | Renamed_elementary of
      {
        usage: usage;
      }
  | Renamed_struct of
      {
        fields: item_definitions;
      }
(*   | RenamedFixedTable of *)
(*       { *)
(*         items: renamed_item_layout nel; *)
(*         length: int with_loc; *)
(*       } *)

(* type data_const_record = *)
(*   { *)
(*     const_name: Cobol_ptree.name with_loc; *)
(*     const_descr: Cobol_ptree.constant_item_descr; *)
(*     const_layout: const_layout; *)
(*   } *)
(* and const_layout = *)
(*   | ElementaryConstant of *)
(*       { *)
(*         (\* value: ?; *\) *)
(*         class_: unit;                                           (\* -- for now *\) *)
(*       } *)
(*   | ConstantRecord of *)
(*       { *)
(*         (\* value: ?; *\) *)
(*         class_: unit option;                                    (\* -- for now *\) *)
(*       } *)

type item =
  | Data_item of
      {
        record: record;
        def: item_definition with_loc;
      }
  | Data_renaming of                                              (* not sure *)
      {
        record: record;
        def: record_renaming with_loc;
      }
  (* | Const_record: data_const_record -> definition *)

(* screen: "_ OCCURS n TIMES" only. Max 2 dimensions. *)
