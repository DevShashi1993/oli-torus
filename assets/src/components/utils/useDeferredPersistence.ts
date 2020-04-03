import * as Immutable from 'immutable';
import { useState, useEffect, useRef } from 'react';

const quietPeriodInMs = 3000;
const maxDeferredTimeInMs = 15000;

export type PersistenceState = Idle | Pending | InFlight;

export interface Idle {
  type: 'Idle';
}
export interface Pending {
  type: 'Pending';
  timer: any;
  timerStart: number;
}
export interface InFlight {
  type: 'InFlight';
}


function usePrevious(value: any) {
  const ref = useRef();
  useEffect(() => {
    ref.current = value;
  });
  return ref.current;
}

const useBeforeUnload = (
  issueSaveRequest: (body: any) => Promise<any>,
  status: PersistenceState,
  pending: any) => {

  const handleBeforeunload = (evt: BeforeUnloadEvent) => {
    if (status.type === 'Pending') {
      issueSaveRequest(pending);
    }
  };

  useEffect(() => {
    window.addEventListener('beforeunload', handleBeforeunload);
    return () => window.removeEventListener('beforeunload', handleBeforeunload);
  }, [status, pending]);
};


export function useDeferredPersistence(
  issueSaveRequest: (body: any) => Promise<any>, content: Immutable.List<any>) {

  const [status, setStatus] = useState({ type: 'Idle' } as PersistenceState);
  const [pending, setPending] = useState(content);
  useBeforeUnload(issueSaveRequest, status, pending);

  const previous = usePrevious(status);
  useEffect(() => {

    if (previous === status) {
      if ((status as any).type === 'Idle' && pending !== content) {
        deferSave(content);
      } else if ((status as any).type === 'Pending' && pending !== content) {
        deferSave(content);
      } else if ((status as any).type === 'InFlight' && pending !== content) {
        deferSave(content);
      }
    }

  }, [content, pending, status]);

  function now() {
    return new Date().getTime();
  }

  function requestFinished(lastPending: any) {
    if (pending !== lastPending) {
      deferSave(pending, true);
    } else {
      setStatus({ type: 'Idle' });
    }
  }

  function persist() : Promise<{}> {
    return new Promise(() => {

      setStatus({ type: 'InFlight' });

      issueSaveRequest((pending as any).toArray())
        .then(() => requestFinished(pending))
        .catch(() => requestFinished(pending));
    });
  }

  function deferSave(content: any, postedWhileInFlight = false) {

    const initTimer = () => setTimeout(() => {
      persist();
    },
      quietPeriodInMs);

    if (status.type === 'Idle' || postedWhileInFlight) {
      setStatus({
        type: 'Pending',
        timer: initTimer(),
        timerStart: now(),
      });
      setPending(content);

    } else if (status.type === 'Pending') {
      clearTimeout((status as Pending).timer);

      if (now() - (status as Pending).timerStart > maxDeferredTimeInMs) {
        persist();
      } else {
        setStatus({
          type: 'Pending',
          timer: initTimer(),
          timerStart: (status as Pending).timerStart,
        });
        setPending(content);
      }

    } else if (status.type === 'InFlight') {
      setStatus({
        type: 'InFlight',
      });
      setPending(pending);
    }

  }

  return status;
}