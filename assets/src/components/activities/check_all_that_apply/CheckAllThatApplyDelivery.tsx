import React, { useState } from 'react';
import ReactDOM from 'react-dom';
import { DeliveryElement, DeliveryElementProps,
  EvaluationResponse, ResetActivityResponse, RequestHintResponse } from '../DeliveryElement';
import { CheckAllThatApplyModelSchema } from './schema';
import { Choice } from 'components/activities/multiple_choice/schema';
import * as ActivityTypes from '../types';
import { HtmlContentModelRenderer } from 'data/content/writers/renderer';
import { Stem } from '../common/DisplayedStem';
import { Hints } from '../common/DisplayedHints';
import { Reset } from '../common/Reset';
import { Evaluation } from '../common/Evaluation';

type Evaluation = {
  score: number,
  outOf: number,
  feedback: ActivityTypes.RichText,
};

interface ChoicesProps {
  choices: Choice[];
  selected: string[];
  onSelect: (id: string) => void;
  isEvaluated: boolean;
}
const Choices = ({ choices, selected, onSelect, isEvaluated }: ChoicesProps) => {
  const isSelected = (choiceId: string) => !!selected.find(s => s === choiceId);
  return (
    <div className="choices">
    {choices.map((choice, index) =>
      <Choice
        key={choice.id}
        onClick={() => onSelect(choice.id)}
        selected={isSelected(choice.id)}
        choice={choice}
        isEvaluated={isEvaluated}
        index={index} />)}
    </div>
  );
};

interface ChoiceProps {
  choice: Choice;
  index: number;
  selected: boolean;
  onClick: () => void;
  isEvaluated: boolean;
}
const Choice = ({ choice, index, selected, onClick, isEvaluated }: ChoiceProps) => {
  return (
    <div key={choice.id}
      onClick={isEvaluated ? undefined : onClick}
      className={`choice ${selected ? 'selected' : ''}`}>
        <span className="choice-index">{index + 1}</span>
      <HtmlContentModelRenderer text={choice.content} />
    </div>
  );
};

const CheckAllThatApply = (props: DeliveryElementProps<CheckAllThatApplyModelSchema>) => {

  const [model, setModel] = useState(props.model);
  const [attemptState, setAttemptState] = useState(props.state);
  const [hints, setHints] = useState(props.state.parts[0].hints);
  const [hasMoreHints, setHasMoreHints] = useState(props.state.parts[0].hasMoreHints);
  const [selected, setSelected] = useState<string[]>(
    props.state.parts[0].response === null
    ? []
    : props.state.parts[0].response.input.split('')
      .reduce(
        (acc: string[], curr: string) => acc.concat([curr]),
        []));

  const { stem, choices } = model;

  const isEvaluated = attemptState.score !== null;
  const selectedToInput = () => selected.join(' ');

  const onSubmit = () => {
    console.log('input', selectedToInput());
    props.onSubmitActivity(attemptState.attemptGuid,
      // update this input too
      [{ attemptGuid: attemptState.parts[0].attemptGuid, response: { input: selectedToInput() } }])
      .then((response: EvaluationResponse) => {
        if (response.evaluations.length > 0) {
          console.log('response.evaluations', response.evaluations)
          const { score, out_of, feedback, error } = response.evaluations[0];
          const parts = [Object.assign({}, attemptState.parts[0], { feedback, error })];
          const updated = Object.assign({}, attemptState, { score, outOf: out_of, parts });
          setAttemptState(updated);
        }
      });
  };

  const updateSelection = (id: string) => {
    const newSelection = !!selected.find(s => s === id)
      ? selected.filter(s => s !== id)
      : selected.concat([id]);
    setSelected(newSelection);
  }

  const onSelect = (id: string) => {
    // Update local state by adding or removing the id
    updateSelection(id);

    // Post the student response to save it
    // Here we will make a list of the selected ids like { input: [id1, id2, id3].join(' ')}
    // Then in the rule evaluator, we will say
    // `input like id1 && input like id2 && input like id3`
    props.onSaveActivity(attemptState.attemptGuid,
      [{ attemptGuid: attemptState.parts[0].attemptGuid, response: { input: selectedToInput() } }]);
  };

  const onRequestHint = () => {
    props.onRequestHint(attemptState.attemptGuid, attemptState.parts[0].attemptGuid)
    .then((state: RequestHintResponse) => {
      if (state.hint !== undefined) {
        setHints([...hints, state.hint] as any);
      }
      setHasMoreHints(state.hasMoreHints);
    });
  };

  const onReset = () => {
    props.onResetActivity(attemptState.attemptGuid)
    .then((state: ResetActivityResponse) => {
      setSelected([]);
      setAttemptState(state.attemptState);
      setModel(state.model as CheckAllThatApplyModelSchema);
      setHints([]);
      setHasMoreHints(props.state.parts[0].hasMoreHints);
    });
  };

  const evaluationSummary = isEvaluated
    ? <Evaluation key="evaluation" attemptState={attemptState}/>
    : null;

  const reset = isEvaluated && !props.graded
    ? (<div className="d-flex my-3">
        <div className="flex-fill"></div>
        <Reset hasMoreAttempts={attemptState.hasMoreAttempts} onClick={onReset} />
      </div>
    )
    : null;

  const ungradedDetails = props.graded ? null : [
    evaluationSummary,
    <Hints key="hints" onClick={onRequestHint} hints={hints}
      hasMoreHints={hasMoreHints} isEvaluated={isEvaluated}/>];

  const maybeSubmitButton = props.graded
    ? null
    : (
      <button
        className="btn btn-primary mt-2" disabled={isEvaluated} onClick={onSubmit}>
        Submit
      </button>
    );

  return (
    <div className={`activity multiple-choice-activity ${isEvaluated ? 'evaluated' : ''}`}>
      <div className="activity-content">
        <Stem stem={stem} />
        <Choices choices={choices} selected={selected}
          onSelect={onSelect} isEvaluated={isEvaluated}/>
        {ungradedDetails}
        {maybeSubmitButton}
      </div>
      {reset}
    </div>
  );
};

// Defines the web component, a simple wrapper over our React component above
export class CheckAllThatApplyDelivery extends DeliveryElement<CheckAllThatApplyModelSchema> {
  render(mountPoint: HTMLDivElement, props: DeliveryElementProps<CheckAllThatApplyModelSchema>) {
    ReactDOM.render(<CheckAllThatApply {...props} />, mountPoint);
  }
}

// Register the web component:
const manifest = require('./manifest.json') as ActivityTypes.Manifest;
window.customElements.define(manifest.delivery.element, CheckAllThatApplyDelivery);
