import { Video } from "@remotion/media";
import {
  AbsoluteFill,
  CanvasImage,
  interpolate,
  Sequence,
  Series,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const ink = "#101614";
const mint = "#86d7c4";
const white = "#f5f8f6";
const font = "Arial, Helvetica, sans-serif";

const title = (size: number): React.CSSProperties => ({
  color: white,
  fontFamily: font,
  fontSize: size,
  fontWeight: 700,
  lineHeight: 1.04,
  letterSpacing: 0,
  margin: 0,
});

const Kicker = ({ children }: { children: React.ReactNode }) => (
  <div
    style={{
      color: mint,
      fontFamily: font,
      fontSize: 30,
      fontWeight: 700,
      letterSpacing: 2,
      textTransform: "uppercase",
    }}
  >
    {children}
  </div>
);

const PhotoCompare = ({ reveal }: { reveal: number }) => {
  const { fps } = useVideoConfig();
  const photoStyle: React.CSSProperties = {
    position: "absolute",
    left: -520,
    top: 0,
    width: 1700,
    height: 957,
  };

  return (
    <div
      style={{
        position: "absolute",
        top: 435,
        width: 1080,
        height: 957,
        overflow: "hidden",
      }}
    >
      <CanvasImage
        src={staticFile("portrait-original.jpg")}
        premountFor={fps}
        style={photoStyle}
      />
      <CanvasImage
        src={staticFile("portrait-blurred.png")}
        premountFor={fps}
        style={{ ...photoStyle, clipPath: `inset(0 ${100 - reveal}% 0 0)` }}
      />
      <div
        style={{
          position: "absolute",
          left: `${reveal}%`,
          top: 0,
          width: 5,
          height: "100%",
          backgroundColor: mint,
          opacity: reveal > 1 && reveal < 99 ? 1 : 0,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 52,
          bottom: 40,
          color: white,
          backgroundColor: "#101614dd",
          padding: "12px 20px",
          fontFamily: font,
          fontSize: 26,
          fontWeight: 700,
          opacity: reveal > 12 ? 1 : 0,
        }}
      >
        BLURLY
      </div>
      <div
        style={{
          position: "absolute",
          right: 52,
          bottom: 40,
          color: white,
          backgroundColor: "#101614dd",
          padding: "12px 20px",
          fontFamily: font,
          fontSize: 26,
          fontWeight: 700,
          opacity: reveal < 88 ? 1 : 0,
        }}
      >
        ORIGINAL
      </div>
    </div>
  );
};

const phoneMediaStyle: React.CSSProperties = {
  position: "absolute",
  left: -3,
  top: -3,
  width: 766,
  height: 1652,
};

const Phone = ({ children }: { children: React.ReactNode }) => (
  <div
    style={{
      position: "absolute",
      left: 160,
      top: 280,
      width: 760,
      height: 1646,
      overflow: "hidden",
      border: "2px solid #4b615a",
      borderRadius: 8,
      backgroundColor: "#0d1110",
    }}
  >
    {children}
  </div>
);

const Hook = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const reveal = interpolate(frame, [0.8 * fps, 3.4 * fps], [0, 100], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ backgroundColor: ink }}>
      <div style={{ position: "absolute", left: 78, top: 104 }}>
        <Kicker>Before / after</Kicker>
        <h1 style={{ ...title(88), marginTop: 28 }}>
          Make the subject
          <br />
          stand out.
        </h1>
      </div>
      <PhotoCompare reveal={reveal} />
      <div style={{ position: "absolute", left: 78, top: 1485 }}>
        <p style={{ ...title(48), fontWeight: 500 }}>
          Same portrait. A softer background.
        </p>
        <p
          style={{
            color: "#aebcb6",
            fontFamily: font,
            fontSize: 27,
            marginTop: 36,
          }}
        >
          Sample portrait - Actual Blurly result
        </p>
      </div>
    </AbsoluteFill>
  );
};

const Intensity = () => {
  const { fps } = useVideoConfig();
  return (
    <AbsoluteFill style={{ backgroundColor: ink }}>
      <div style={{ position: "absolute", left: 78, top: 78 }}>
        <Kicker>On the phone</Kicker>
        <h1 style={{ ...title(76), marginTop: 24 }}>Dial in the blur.</h1>
        <p
          style={{
            color: "#aebcb6",
            fontFamily: font,
            fontSize: 25,
            marginTop: 14,
          }}
        >
          Processing wait shortened
        </p>
      </div>
      <Phone>
        <Video
          name="Real app: adjust blur intensity"
          src={staticFile("intensity-demo.mp4")}
          premountFor={fps}
          muted
          style={phoneMediaStyle}
        />
      </Phone>
    </AbsoluteFill>
  );
};

const Refine = () => {
  const { fps } = useVideoConfig();
  return (
    <AbsoluteFill style={{ backgroundColor: ink }}>
      <div style={{ position: "absolute", left: 78, top: 78 }}>
        <Kicker>Finishing touch</Kicker>
        <h1 style={{ ...title(76), marginTop: 24 }}>Brush the details.</h1>
      </div>
      <Phone>
        <Video
          name="Real app: open Refine subject"
          src={staticFile("refine-demo.mp4")}
          premountFor={fps}
          muted
          style={phoneMediaStyle}
        />
        <Sequence
          from={3.5 * fps}
          durationInFrames={2.5 * fps}
          premountFor={fps}
        >
          <CanvasImage
            src={staticFile("refine-preview.png")}
            premountFor={fps}
            style={phoneMediaStyle}
          />
        </Sequence>
      </Phone>
    </AbsoluteFill>
  );
};

const Result = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const reveal = interpolate(frame, [0.3 * fps, 2.7 * fps], [45, 100], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ backgroundColor: ink }}>
      <div style={{ position: "absolute", left: 78, top: 104 }}>
        <Kicker>The result</Kicker>
        <h1 style={{ ...title(88), marginTop: 28 }}>
          Less distraction.
          <br />
          More focus.
        </h1>
      </div>
      <PhotoCompare reveal={reveal} />
      <div style={{ position: "absolute", left: 78, top: 1490 }}>
        <p style={{ ...title(47), fontWeight: 500 }}>
          Made with Blurly on Android.
        </p>
      </div>
    </AbsoluteFill>
  );
};

const CallToAction = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const lift = interpolate(frame, [0, 0.6 * fps], [40, 0], {
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ backgroundColor: ink }}>
      <CanvasImage
        src={staticFile("portrait-blurred.png")}
        premountFor={fps}
        style={{
          position: "absolute",
          left: -350,
          top: 1320,
          width: 1400,
          height: 788,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 88,
          right: 88,
          top: 405,
          textAlign: "center",
          translate: `0 ${lift}px`,
        }}
      >
        <CanvasImage
          src={staticFile("blurly-icon.png")}
          premountFor={fps}
          style={{ width: 240, height: 240, margin: "0 auto" }}
        />
        <h1 style={{ ...title(118), marginTop: 34 }}>Blurly</h1>
        <p style={{ ...title(48), fontWeight: 500, marginTop: 32 }}>
          Put the focus where it belongs.
        </p>
        <div
          style={{
            display: "inline-block",
            backgroundColor: mint,
            color: ink,
            fontFamily: font,
            fontSize: 40,
            fontWeight: 700,
            padding: "25px 44px",
            borderRadius: 8,
            marginTop: 94,
          }}
        >
          Get it on Google Play
        </div>
        <p
          style={{
            color: "#aebcb6",
            fontFamily: font,
            fontSize: 30,
            marginTop: 42,
          }}
        >
          blurly-mu.vercel.app
        </p>
      </div>
    </AbsoluteFill>
  );
};

export const BlurlySocialDemo = () => {
  const { fps } = useVideoConfig();
  return (
    <Series>
      <Series.Sequence
        name="Before and after hook"
        durationInFrames={4 * fps}
        premountFor={fps}
      >
        <Hook />
      </Series.Sequence>
      <Series.Sequence
        name="Adjust blur in the app"
        durationInFrames={4 * fps}
        premountFor={fps}
      >
        <Intensity />
      </Series.Sequence>
      <Series.Sequence
        name="Refine subject"
        durationInFrames={6 * fps}
        premountFor={fps}
      >
        <Refine />
      </Series.Sequence>
      <Series.Sequence
        name="Finished result"
        durationInFrames={4 * fps}
        premountFor={fps}
      >
        <Result />
      </Series.Sequence>
      <Series.Sequence
        name="Google Play call to action"
        durationInFrames={3 * fps}
        premountFor={fps}
      >
        <CallToAction />
      </Series.Sequence>
    </Series>
  );
};
