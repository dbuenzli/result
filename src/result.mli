(*---------------------------------------------------------------------------
   Copyright 2014 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Error handling for OCaml.

  Open the module to use it, this defines only one type and a module
  in your scope. To use the {!R.Infix} operators you can open {!Result_infix}
  instead.

  {e Release %%VERSION%% - %%MAINTAINER%% } *)

(** {1 Interface} *)

type ('a, 'b) result = [ `Ok of 'a | `Error of 'b ]
(** The type for results. *)

(** Result value combinators. *)
module R : sig

  (** {1 Results} *)

  type ('a, 'b) t = [ `Ok of 'a | `Error of 'b ]
  (** The type for results. *)

  val ret : 'a -> ('a, 'b) result
  (** [ret v] is [`Ok v]. *)

  val error : 'b -> ('a, 'b) result
  (** [error e] is [`Error e]. *)

  val reword_err : ('b -> 'c) -> ('a, 'b) result -> ('a, 'c) result
  (** [reword_err reword r] is:
      {ul
      {- [`Ok v] if [r = `Ok v]}
      {- [`Error (reword e)] if [r = `Error e]}} *)

  val get_ok : ('a, 'b) result -> 'a
  (** [get r] is [v] if [r = `Ok v] and @raise Invalid_argument otherwise. *)

  val get_error : ('a, 'b) result -> 'b
  (** [get_error r] is [e] if [r = `Error e] and @raise Invalid_argument
      otherwise. *)

  val pp :
    pp_ok:(Format.formatter -> 'a -> unit) ->
    pp_err:(Format.formatter -> 'b -> unit) -> Format.formatter ->
    ('a, 'b) result -> unit
  (** [pp pp_ok pp_err ppf r] prints [r] on [ppf] using [pp_ok] and
      [pp_err]. *)

  (** {1 Composing results} *)

  val bind : ('a, 'b) result -> ('a -> ('a, 'b) result) -> ('a, 'b) result
  (** [bind r f] is [f v] if [r = `Ok v] and [r] if [r = `Error _]. *)

  val map : ('a, 'b) result -> ('a -> 'c) -> ('c, 'b) result
  (** [map r f] is [bind r (fun v -> ret (f v))]. *)

  val join : (('a, 'b) result, 'b) result -> ('a, 'b) result
  (** [join r] is [v] if [r = `Ok v] and [r] otherwise. *)

  val ( >>= ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result
  (** [r >>= f] is {!bind}[ r f]. *)

  val ( >>| ) : ('a, 'b) result -> ('a -> 'c) -> ('c, 'b) result
  (** [r >>| f] is {!map}[ r f]. *)

  (** Infix operators.

      Gathers {!R}'s infix operators. *)
  module Infix : sig

   (** {1 Infix operators} *)

    val ( >>= ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result
    (** [(>>=)] is {!R.( >>= )}. *)

    val ( >>| ) : ('a, 'b) result -> ('a -> 'c) -> ('c, 'b) result
    (** [(>>|)] is {!R.( >>| )}. *)
  end

  (** {1 Error messages} *)

  type err_msg = [ `Msg of string ]
  (** The type for error messages. *)

  val pp_err_msg : Format.formatter -> err_msg -> unit
  (** [pp_msg ppf m] prints [m] on [ppf]. *)

  val err_msg : ('a, Format.formatter, unit, ('b, [> err_msg]) result)
      format4 -> 'a
  (** [err_msg fmt ...] is an error message formatted according to [fmt]. *)

  val reword_err_msg : ?replace:bool -> (unit -> string)  ->
    ('a, err_msg) result -> ('a, err_msg) result
  (** [reword_err msg r] uses [msg ()] for the error message in case
      of [`Error]. If replace is [false] (default), [msg] is
      concatenated, on a new line, to the old message. *)

  val err_to_err_msg : pp:(Format.formatter -> 'b -> unit) ->
    ('a, 'b) result -> ('a, [> err_msg]) result
  (** [err_to_err_msg pp r] converts errors in [r] with [pp] to an error
      message. *)

  val err_msg_to_invalid_arg : ('a, err_msg) result -> 'a
  (** [err_msg_to_invalid_arg r] is [v] if [r = `Ok v] and
      @raise Invalid_argument with the error message otherwise. *)

  (** {1 Handling unexpected exceptions}

      {e Getting rid of [null] was not enough}. *)

  type err_exn = [ `Exn of Printexc.raw_backtrace ]
  (** The type for exception errors. *)

  val pp_err_exn : Format.formatter -> err_exn -> unit
  (** [pp_err_exn ppf e] prints [e] on [ppf]. *)

  val trap_exn : ('a -> 'b) -> 'a -> ('b, [> err_exn]) result
  (** [trap_exn f v] is [f v] and traps any exception that may
      occur. *)

  val err_exn_to_msg : ('a, err_exn) result -> ('a, [> err_msg]) result
  (** [err_exn_to_msg r] converts exception errors in [r] to an error
      message. *)

  (** {1 Converting} *)

  val to_option : ('a, 'b) result -> 'a option
  (** [to_option r] is [Some v] if [r = `Ok v] and [None] otherwise. *)

  val of_option : none:('a, 'b) result -> 'a option -> ('a, 'b) result
  (** [of_option ~none r] is [`Ok v] if [r = Some v] and [none] otherwise. *)

  (** {1 Ignoring errors}

      {b Warning.} Using these functions is, most of the time, a bad idea. *)

  val ignore_err : use:'a -> ('a, 'b) result -> 'a
  (** [ignore_err ~use r] is [v] if [r = `Ok v] and [use] otherwise. *)

  val ignore_errk : use:'a -> ('a, 'b) result -> ('a, 'b) result
  (** [ignore_errk ~use r] is:
      {ul
      {- [r] if [r = `Ok v]}
      {- [`Ok use] if [r = `Error _].}} *)
end

(*---------------------------------------------------------------------------
   Copyright 2014 Daniel C. Bünzli.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

   3. Neither the name of Daniel C. Bünzli nor the names of
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ---------------------------------------------------------------------------*)
