<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from './lib/supabase';
  import type { GroceryItem } from './lib/types';
  import { Auth } from '@supabase/auth-ui-svelte';
  import { ThemeSupa } from '@supabase/auth-ui-shared';
  import { user } from './lib/store';

  let items: GroceryItem[] = [];
  let newItem = '';
  let quantity = 1;
  let unit = 'יח.';

  const units = ['יח.', 'ק"ג', 'גר.', 'ליטר', 'מ"ל'];
//+++++++++++++++++++++++++++++++++++++++++++
onMount(async () => {
  // Set up auth state listener
  console.log("Hello SupaBase!")
  const { data: authSubscription } = supabase.auth.onAuthStateChange((event, session) => {
    user.set(session?.user || null);
    if (session?.user) {
      loadItems();
      subscribeToChanges();
    }
  });

  // Subscribe to real-time changes
  function subscribeToChanges() {
    supabase
      .channel('realtime:grocery_items')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'grocery_items' },
        (payload) => {
          console.log('Change received!', payload);
          updateItems(payload);
        }
      )
      .subscribe();
  }

  return () => {
    authSubscription?.unsubscribe();
    supabase.removeChannel('realtime:grocery_items');
  };
});

// Function to update items based on Supabase changes
function updateItems(payload) {
  if (payload.eventType === 'INSERT') {
    items = [...items, payload.new];
  } else if (payload.eventType === 'UPDATE') {
    items = items.map((item) => (item.id === payload.new.id ? payload.new : item));
  } else if (payload.eventType === 'DELETE') {
    items = items.filter((item) => item.id !== payload.old.id);
  }
}

//+++++++++++++++++++++++++++++++++++++++++++
  async function loadItems() {
    const { data, error } = await supabase
      .from('grocery_items')
      .select('*')
      .order('id', { ascending: true });

    if (error) {
      console.error('Error fetching items:', error);
      return;
    }

    items = data || [];
  }

  async function addItem() {
    if (!newItem.trim()) return;

    const { data, error } = await supabase
      .from('grocery_items')
      .insert([
        {
          item: newItem,
          quantity,
          unit,
          is_selected: false
        }
      ])
      .select();

    if (error) {
      console.error('Error adding item:', error);
      return;
    }

    if (data) {
      items = [...items, data[0]];
      newItem = '';
      quantity = 1;
      unit = 'יח.';
    }
  }

  async function deleteItem(id: number) {
    const { error } = await supabase
      .from('grocery_items')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Error deleting item:', error);
      return;
    }

    items = items.filter(item => item.id !== id);
  }

  async function toggleSelect(id: number) {
    const item = items.find(i => i.id === id);
    if (!item) return;

    const { error } = await supabase
      .from('grocery_items')
      .update({ is_selected: !item.is_selected })
      .eq('id', id);

    if (error) {
      console.error('Error updating item:', error);
      return;
    }

    items = items.map(i => 
      i.id === id ? { ...i, is_selected: !i.is_selected } : i
    );
  }

  async function signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) console.error('Error signing out:', error);
    items = [];
  }
</script>

<main class="container">
  {#if !$user}
    <div class="auth-container">
      <h1 class="dana">ממי, תביא לי בבקשה מהסופר:</h1>
      <p class="auth-description">כדי להשתמש ברשימת הקניות, יש להתחבר או ליצור חשבון חדש</p>
      <Auth 
        supabaseClient={supabase} 
        appearance={{ 
          theme: ThemeSupa,
          variables: {
            default: {
              colors: {
                brand: '#4CAF50',
                brandAccent: '#45a049'
              }
            }
          },
          labels: {
            sign_in: {
              email_label: 'כתובת דואר אלקטרוני',
              password_label: 'סיסמה',
              button_label: 'התחבר',
              loading_button_label: 'מתחבר...',
              social_provider_text: 'התחבר באמצעות',
              link_text: 'כבר יש לך חשבון? התחבר'
            },
            sign_up: {
              email_label: 'כתובת דואר אלקטרוני',
              password_label: 'סיסמה',
              button_label: 'הרשם',
              loading_button_label: 'נרשם...',
              social_provider_text: 'הרשם באמצעות',
              link_text: 'אין לך חשבון? הרשם'
            }
          }
        }}
        localization={{
          variables: {
            sign_in: {
              email_label: 'כתובת דואר אלקטרוני',
              password_label: 'סיסמה',
              button_label: 'התחבר',
              loading_button_label: 'מתחבר...',
              social_provider_text: 'התחבר באמצעות',
              link_text: 'כבר יש לך חשבון? התחבר'
            },
            sign_up: {
              email_label: 'כתובת דואר אלקטרוני',
              password_label: 'סיסמה',
              button_label: 'הרשם',
              loading_button_label: 'נרשם...',
              social_provider_text: 'הרשם באמצעות',
              link_text: 'אין לך חשבון? הרשם'
            }
          }
        }}
        providers={[]}
      />
    </div>
  {:else}
    <div class="header">
      <h1>ממי, תביא לי מהסופר:</h1>
      <button class="signout-btn" on:click={signOut}>התנתק</button>
    </div>
    
    <div class="input-form">
      <div class="input-row">
        <input
          type="text"
          bind:value={newItem}
          placeholder="פריט"
          on:keypress={(e) => e.key === 'Enter' && addItem()}
        />
        <input
          type="number"
          bind:value={quantity}
          min="1"
          placeholder="כמות"
          class="quantity-input"
        />
        <select bind:value={unit} class="unit-select">
          {#each units as unitOption}
            <option value={unitOption}>{unitOption}</option>
          {/each}
        </select>
      </div>
      <button on:click={addItem} class="add-button">הוסף מוצר</button>
    </div>

    <ul class="items-list">
      {#each items as item (item.id)}
        <!-- svelte-ignore a11y-click-events-have-key-events -->
        <!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
        <li 
          class:selected={item.is_selected}
          on:click={() => toggleSelect(item.id)}
        >
          <span class="item-name">{item.item}</span>
          <span class="item-quantity">{item.quantity} {item.unit}</span>
          <button 
            class="delete-btn"
            on:click|stopPropagation={() => deleteItem(item.id)}
          >
            🗑️
          </button>
        </li>
      {/each}
    </ul>
  {/if}
</main>

<style>
  .auth-container {
    max-width: 400px;
    margin: 2rem auto;
    padding: 1rem;
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    text-align: center;
  }

  .auth-description {
    margin: 1rem 0;
    color: #666;
  }

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
  }

  .signout-btn {
    background-color: #ff4444;
    padding: 0.5rem 0.5rem;
    font-size: small;
  }

  .signout-btn:hover {
    background-color: #ff0000;
  }

  .input-form {
    background: rgba(45, 70, 94, 0);
    padding: 0.4rem;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    margin-bottom: 1rem;
  }

  .input-row {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 0.5rem;

  }

  .quantity-input {
    width: 50px;
    flex-shrink: 0;
  }

  .unit-select {
    width: 50px;
    
    flex-shrink: 0;
    padding: 0rem;
    border: 0px solid #ddd;
    border-radius: 8px;
    font-size: x-large;
  }

  .add-button {
    width: 100%;
    font-family: "dana", sans-serif;
    font-size: 2.3rem;
    letter-spacing: 0.1rem;
    font-weight: 900;
  }

  .items-list {
    list-style: none;
    padding: 0.4em;
    margin: 0;
    border-radius: 8px;
    letter-spacing: 0.1rem;
    
  }

  li {
    display: flex;
    align-items: center;
    padding: 0.75rem;
    background: white;
    margin-bottom: 0.5rem;
    border-radius: 4px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    cursor: pointer;
    transition: background-color 0.2s;
    border-radius: 8px;
  }

  .item-name {
    font-family: "dana", sans-serif;
    flex-grow: 1;
    text-align: center;
    font-size: x-large;
  }

  .item-quantity {
    margin: 0 0 0 1.5rem;
    color: #1606f5;
    font-size: x-large;
  }

  .delete-btn {
    background: #ff4444;
    color: white;
    border: none;
    width: 30px;
    height: 0px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0;
    font-size: 25px;
  }

  .delete-btn:hover {
    background: #ff0000;
  }

  h1 {
    font-family: "dana", sans-serif;
    font-size: 2.3rem;
    margin: 0;
    color: #fafa05;
    letter-spacing: 0.1rem;
    font-weight: 800;
    padding-right: 0.2em;
  }
</style>