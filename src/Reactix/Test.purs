module Reactix.Test
  ( act
  , render
  , Rendered
  , fireEvent, fireClick
  , cleanup
  ) where

import Prelude
import Effect ( Effect )
import Effect.Uncurried ( EffectFn1, runEffectFn1, EffectFn2, runEffectFn2 )
import Data.Function.Uncurried ( Fn2, runFn2 )
import DOM.Simple as DOM
import Reactix.React ( react, Element )
import FFI.Simple ( (..), (...), delay )
import DOM.Simple.Console

foreign import data TestUtils :: Type

foreign import testUtils :: TestUtils

foreign import data Testing :: Type

foreign import testingLibrary :: Testing

type Rendered =
  { getByText :: String -> Effect Element
  , getByTestId :: String -> Effect Element
  , container :: DOM.Element
  , asFragment :: Effect DOM.Fragment }

render :: Element -> Effect Rendered
render e = pure $ raw { getByText=getByText, getByTestId=getByTestId }
  where getByText = runEffectFn1 raw.getByText
        getByTestId = runEffectFn1 raw.getByTestId
        raw = testingLibrary ... "render" $ [e]

-- | Make react behave more predictably in tests
act :: forall t. (Unit -> Effect t) -> Effect t
act f = testUtils ... "act" $ [ delay unit f ]

fireClick :: DOM.Element -> Effect Unit
fireClick = fireEvent "click"

fireEvent :: String -> DOM.Element -> Effect Unit
fireEvent ev el = pure $ (testingLibrary .. "fireEvent") ... ev $ [el]

cleanup :: Effect Unit
cleanup = delay unit $ \_ -> pure $ testingLibrary ... "cleanup" $ []

