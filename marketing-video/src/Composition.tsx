import { Composition } from "remotion";
import { BlurlySocialDemo } from "./BlurlySocialDemo";

export const MyComposition = () => {
  return (
    <Composition
      id="BlurlySocialDemo"
      component={BlurlySocialDemo}
      durationInFrames={630}
      fps={30}
      width={1080}
      height={1920}
    />
  );
};
