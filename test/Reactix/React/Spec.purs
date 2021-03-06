module Reactix.React.Spec where

import Prelude
import Data.Array as A
import Data.Array ( (!!) )
import Data.EuclideanRing (mod)
import Data.Maybe ( Maybe(..) )
import Data.Nullable (null)
import Data.Traversable ( traverse, traverse_, sequence_ )
import Data.Tuple ( Tuple(..) )
import Data.Tuple.Nested ( (/\) )
import Data.Unfoldable (fromMaybe)
import Effect ( Effect )
import Effect.Aff ( Aff, launchAff )
import Effect.Class ( liftEffect )
import Effect.Ref as Ref
import Effect.Uncurried ( EffectFn1, mkEffectFn1, runEffectFn1 )
-- import Effect.Aff (launchAff_)
import Test.Spec ( Spec, describe, it )
import Test.Spec.Assertions ( shouldEqual )
-- import Test.Spec.QuickCheck (quickCheck')
import DOM.Simple as DOM
import DOM.Simple.Document as Document
import DOM.Simple.Element as Element
import DOM.Simple.Node as Node
import DOM.Simple.Event as Event
import DOM.Simple.Types (Element)
import FFI.Simple (delay)
import Reactix as R
import Reactix.Test as RT
import Reactix.DOM.HTML ( button, div, i, text )
import DOM.Simple.Console

staticTest :: Spec Unit
staticTest =
  describe "Basic DOM rendering" $ do
    it "Simple elements" $ do
      root <- liftEffect $ RT.render simple
      let children = Element.children root.container
      (Element.name <$> children) `shouldEqual` ["I"]
      (Element.innerHTML <$> children) `shouldEqual` ["hello world"]
    it "Magic props" $ do
      root <- liftEffect $ RT.render magic
      let children = Element.children root.container
      A.length children `shouldEqual` 1
      let children2 = children >>= Element.children
      let attrNames = A.sort (children >>= Element.attrNames)
      let attrVals =
            do name <- attrNames
               child <- children
               fromMaybe $ Element.attr child name
      ["aria-label", "data-sample"] `shouldEqual` attrNames
      ["example", "example"] `shouldEqual` attrVals
    it "Fragments" $ do
      root <- liftEffect $ RT.render $ frag
      Element.childCount root.container `shouldEqual` 2
      let children = Element.children root.container
      A.length children `shouldEqual` 2
      (Element.name <$> children) `shouldEqual` ["I", "I"]
      (Element.innerHTML <$> children) `shouldEqual` ["hello","world"]
   where
     simple = i {} [ text "hello world" ]
     magic = div {aria: {label: "example"}, "data": {sample: "example"}} []
     frag = i {} [ text "hello" ] <> i {} [ text "world" ]

getAttr :: String -> Element -> Maybe String
getAttr = flip Element.attr

type CounterProps = ( count :: Int )

counterCpt :: R.Component CounterProps
counterCpt = R.hooksComponent "Counter" cpt
  where
    cpt {count} _ = do
      y /\ setY <- R.useState' count
      pure $ div { className: "counter" }
        [ button { type: "button", on: { click: \_ -> setY (_ + 1) } } [ text "++" ]
        , div {} [ text (show y) ] ]

counterTest :: Spec Unit
counterTest =
  describe "Counter" do
    it "Works for plain components" $ do
      let counter = R.createElement counterCpt {count: 0} []
      liftEffect (RT.render counter) >>= test
    it "Works for memoised components" $ do
      let counter = R.createElement (R.memo counterCpt (==)) {count: 0} []
      liftEffect (RT.render counter) >>= test
    it "works for memo'ised components" $ do
      let counter = R.createElement (R.memo' counterCpt) {count: 0} []
      liftEffect (RT.render counter) >>= test
  where
    test root = do
      let children = Element.children root.container
      A.length children `shouldEqual` 1
      let children2 = children >>= Element.children
      A.length children2 `shouldEqual` 2
      (Element.name <$> children2) `shouldEqual` ["BUTTON", "DIV"]
      (Element.innerHTML <$> children2) `shouldEqual` ["++", "0"]
      liftEffect $ traverse_ RT.fireClick (children2 !! 0)
      let children3 = Element.children root.container >>= Element.children
      A.length children3 `shouldEqual` 2
      (Element.innerHTML <$> children3) `shouldEqual` ["++", "1"]
      liftEffect $ traverse_ RT.fireClick (children3 !! 0)
      let children4 = Element.children root.container >>= Element.children
      A.length children4 `shouldEqual` 2
      (Element.innerHTML <$> children4) `shouldEqual` ["++", "2"]

data BicounterOp = Inc | Dec

-- No bi erasure here
bicounterCpt :: R.Component CounterProps
bicounterCpt = R.hooksComponent "Bicounter" cpt
  where
    cpt {count} _ = do
      y /\ reduceY <- R.useReducer' reduce count
      pure $ div { className: "counter" }
        [ button { type: "button",  on: { click: \_ -> reduceY Inc } } [ text "++" ]
        , button { type: "button",  on: { click: \_ -> reduceY Dec } } [ text "--" ]
        , div {} [ text (show y) ] ]
    reduce count Inc = count + 1
    reduce count Dec = count - 1

bicounterTest :: Spec Unit
bicounterTest =
  describe "Bicounter" do
    it "Works for plain components" $ do
      let counter = R.createElement bicounterCpt {count: 0} []
      liftEffect (RT.render counter) >>= test
    it "Works for memoised components" $ do
      let counter = R.createElement (R.memo bicounterCpt (==)) {count: 0} []
      liftEffect (RT.render counter) >>= test
    it "works for memo'ised components" $ do
      let counter = R.createElement (R.memo' bicounterCpt) {count: 0} []
      liftEffect (RT.render counter) >>= test
  where
    test root = do
      let children = Element.children root.container
      A.length children `shouldEqual` 1
      let children2 = children >>= Element.children
      A.length children2 `shouldEqual` 3
      (Element.name <$> children2) `shouldEqual` ["BUTTON", "BUTTON", "DIV"]
      (Element.innerHTML <$> children2) `shouldEqual` ["++", "--", "0"]
      liftEffect $ traverse_ RT.fireClick (children2 !! 0)
      let children3 = Element.children root.container >>= Element.children
      A.length children3 `shouldEqual` 3
      (Element.innerHTML <$> children3) `shouldEqual` ["++", "--", "1"]
      liftEffect $ traverse_ RT.fireClick (children3 !! 0)
      let children4 = Element.children root.container >>= Element.children
      A.length children4 `shouldEqual` 3
      (Element.innerHTML <$> children4) `shouldEqual` ["++", "--", "2"]
      liftEffect $ traverse_ RT.fireClick (children4 !! 1)
      let children5 = Element.children root.container >>= Element.children
      A.length children5 `shouldEqual` 3
      (Element.innerHTML <$> children4) `shouldEqual` ["++", "--", "1"]
          
data EffectorState = Fresh | Initialised | Done

derive instance eqEffectorState :: Eq EffectorState

instance showEffectorState :: Show EffectorState where
  show Fresh = "fresh"
  show Initialised = "initialised"
  show Done = "done"

type EffectorProps = ( stateRef :: Ref.Ref EffectorState )

effectorCpt :: R.Component EffectorProps
effectorCpt = R.hooksComponent "Effector" cpt
  where cpt {stateRef} _ = do
          R.useEffect $ do
            Ref.write Initialised stateRef
            pure $ Ref.write Done stateRef
          pure $ div {} []

-- TODO: test it's firing at the right time
effectorTest :: Spec Unit
effectorTest =
  describe "Effector" do
    it "Works for plain components" $
      test $ effectorCpt
    it "works for memo'ised components" $
      test $ R.memo' effectorCpt
  where
    test :: forall cpt. R.IsComponent cpt EffectorProps (Array R.Element) => cpt -> Aff Unit
    test cpt = do
      ref <- liftEffect $ Ref.new Fresh
      let effector = R.createElement cpt {stateRef: ref} []
      root <- liftEffect (RT.render effector)
      state <- liftEffect $ Ref.read ref
      state `shouldEqual` Initialised
      liftEffect $ RT.cleanup
      state' <- liftEffect $ Ref.read ref
      state' `shouldEqual` Done

layoutEffectorCpt :: R.Component EffectorProps
layoutEffectorCpt = R.hooksComponent "LayoutEffector" cpt
  where cpt {stateRef} _ = do
          R.useLayoutEffect $ do
            Ref.write Initialised stateRef
            pure $ delay unit $ \_ -> Ref.write Done stateRef
          pure $ div {} []

-- TODO: test it's firing at the right time
layoutEffectorTest :: Spec Unit
layoutEffectorTest =
  describe "LayoutEffector" do
    it "Works for plain components" $
      test $ layoutEffectorCpt
    it "works for memo'ised components" $
      test $ R.memo' layoutEffectorCpt
  where
    test :: forall cpt. R.IsComponent cpt EffectorProps (Array R.Element) => cpt -> Aff Unit
    test cpt = do
      ref <- liftEffect $ Ref.new Fresh
      let effector = R.createElement cpt {stateRef: ref} []
      root <- liftEffect (RT.render effector)
      state <- liftEffect $ Ref.read ref
      state `shouldEqual` Initialised
      liftEffect $ RT.cleanup
      state' <- liftEffect $ Ref.read ref
      state' `shouldEqual` Done

data Theme = Dark | Light

showTheme :: Maybe Theme -> String
showTheme Nothing = "none"
showTheme (Just Dark) = "dark"
showTheme (Just Light) = "light"

type ThemedProps = ( theme :: R.Context (Maybe Theme) )
type ThemeChooserProps = ( )

themedCpt :: R.Component ThemedProps
themedCpt = R.hooksComponent "Themed" cpt
  where
    cpt {theme} _ = do
      theme' <- R.useContext theme
      pure $ div {} [ text (showTheme theme') ]

themeChooserCpt :: R.Component ThemeChooserProps
themeChooserCpt = R.hooksComponent "ThemeChooser" cpt
  where
    cpt props _ = do
      theme /\ setTheme <- R.useState' Nothing
      ref <- R.useRef $ R.createContext Nothing
      let context = R.readRef ref
      pure $
        div {}
        [ button
            { type: "button",  on: {click: \_ ->  setTheme (const Nothing) } }
            [ text "None" ]
        , button
            { type: "button",  on: {click: \_ ->  setTheme (const $ Just Dark) } }
            [ text "Dark" ]
        , button
            { type: "button",  on: {click: \_ -> setTheme (const $ Just Light) } }
            [ text "Light" ]
        , R.provideContext context theme [ R.createElement themedCpt { theme: context } [] ] ]

themeChooserTest :: Spec Unit
themeChooserTest =
  describe "ThemeChooser" do
    it "Works for plain components" $ do
      let themeChooser = R.createElement themeChooserCpt {} []
      liftEffect (RT.render themeChooser) >>= test
  where 
    test root = do
      let children = Element.children root.container
      A.length children `shouldEqual` 1
      let children2 = children >>= Element.children
      A.length children2 `shouldEqual` 4
      (Element.name <$> children2) `shouldEqual` ["BUTTON", "BUTTON", "BUTTON", "DIV"]
      (Element.innerHTML <$> children2) `shouldEqual` ["None", "Dark", "Light", "none"]
      liftEffect $ traverse_ RT.fireClick (children2 !! 0)
      let children3 = (Element.children root.container) >>= Element.children
      A.length children3 `shouldEqual` 4
      (Element.innerHTML <$> children3) `shouldEqual` ["None", "Dark", "Light", "none"]
      liftEffect $ traverse_ RT.fireClick (children3 !! 1)
      let children4 = (Element.children root.container) >>= Element.children
      A.length children4 `shouldEqual` 4
      (Element.innerHTML <$> children4) `shouldEqual` ["None", "Dark", "Light", "dark"]
      liftEffect $ traverse_ RT.fireClick (children4 !! 2)
      let children5 = (Element.children root.container) >>= Element.children
      A.length children5 `shouldEqual` 4
      (Element.innerHTML <$> children5) `shouldEqual` ["None", "Dark", "Light", "light"]
      
    
-- type FizzBuzzProps = ( context :: R.Context Int )

-- fizzBuzzCpt :: R.Component FizzBuzzProps
-- fizzBuzzCpt = R.hooksComponent "FizzBuzz" cpt
--   where
--     cpt {context} _ = do
--       count <- R.useContext context
--       pure $
--         div {}
--         [ button { type: "button",  onClick: onclick reduceY Inc } [ text "++" ]
--         , button { type: "button",  onClick: onclick reduceY Dec } [ text "--" ]
--         , div {} [ text (fizzbuzz count) ] ]
--     fizzbuzz count
--       | count == 0 = "Nothing"
--       | count `mod` 15 == 0 = "FizzBuzz"
--       | count `mod` 3 == 0 = "Fizz"
--       | count `mod` 5 == 0 = "Buzz"
--       | true = show count

-- fizzBuzzTest :: Spec Unit
-- fizzBuzzTest =
--   describe "FizzBuzz" do
--     it "Works for plain components" $
--       test $ fizzBuzzCpt
--     -- it "Works for memo'ised components" $
--     --   test $ R.memo' fizzBuzzCpt
--   where
--     test :: forall cpt. R.IsComponent cpt FizzBuzzProps (Array R.Element) => cpt -> Aff Unit
--     test cpt = do
--       let context = R.createContext 0
    
--       pure unit
    

-- memoTest :: Spec Unit
-- callbackTest :: Spec Unit
-- imperativeHandleTest :: Spec Unit
-- debugValueTest :: Spec Unit

-- listTest :: Spec Unit
-- listTest = pure unit

spec :: Spec Unit
spec = sequence_
  [ staticTest
  , counterTest        -- useState
  , bicounterTest      -- useReducer
  , themeChooserTest   -- useContext, useRef
  , effectorTest       -- useEffect
  , layoutEffectorTest -- useLayoutEffect
  ]
  -- , listTest
  -- ]
