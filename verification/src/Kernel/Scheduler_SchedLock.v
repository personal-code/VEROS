Set Implicit Arguments.

Record Scheduler_SchedLock := mkss{
  
  sched_lock : nat

}.

Definition Scheduler_SchedLock_cstr sl := mkss sl.

Definition inc_sched_lock ss := mkss (S (sched_lock ss)).

Definition zero_sched_lock (ss : Scheduler_SchedLock) := mkss O.

Definition set_sched_lock (ss : Scheduler_SchedLock) sl := mkss sl.

Definition get_sched_lock (ss : Scheduler_SchedLock) :=
  sched_lock ss.
